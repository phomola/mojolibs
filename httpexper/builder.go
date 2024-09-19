package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

var (
	//appCommands sync.Map
	//appPorts    sync.Map
	db          *sql.DB
)

func build(ctx context.Context, id, dir, code string) error {
	sourceFile := "app_" + id + ".mojo"
	f, err := os.Create(dir + "/" + sourceFile)
	if err != nil {
		return err
	}
	if _, err := f.WriteString(code); err != nil {
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	binaryFile := "app_" + id
	cmd := exec.CommandContext(ctx, "magic", "run", "mojo", "build", "-I", "../../mojolibs/src", "-I", "..", "-o", binaryFile, sourceFile)
	cmd.Dir = dir
	var errSb strings.Builder
	cmd.Stderr = &errSb
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%w: %s", err, strings.TrimSpace(errSb.String()))
	}
	if err := os.Mkdir(dir + "_" + id, 0750); err != nil && !os.IsExist(err) {
		return err
	}
	f, err = os.Create(dir + "_" + id + "/Dockerfile")
	if err != nil {
		return err
	}
	if _, err := f.WriteString(`# Mojoapp
FROM ubuntu:latest
WORKDIR /app
COPY . .
ENV HTTP_LIB=./libhttpsrv.so
CMD ["./app_` + id + `"]
`); err != nil {
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	if err := copyFile("libhttpsrv.so", dir + "_" + id + "/libhttpsrv.so"); err != nil {
		return err
	}
	if err := copyFile(dir + "/app_" + id, dir + "_" + id + "/app_" + id); err != nil {
		return err
	}
	if err := os.Chmod(dir + "_" + id + "/app_" + id, 0755); err != nil {
		return err
	}
	cmd = exec.CommandContext(ctx, "docker", "build", "-t", "mojoapps/" + id, ".")
	cmd.Dir = dir + "_" + id
	errSb.Reset()
	cmd.Stderr = &errSb
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("%w: %s", err, strings.TrimSpace(errSb.String()))
	}
	return nil
}

func copyFile(src, dst string) error {
	f1, err := os.Open(src)
	if err != nil {
		return err
	}
	defer f1.Close()
	f2, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer f2.Close()
	_, err = io.Copy(f2, f1)
	return err
}

func run(id, dir string, port int, lib string) error {
	/*if cmd, ok := appCommands.Load(id); ok {
		cmd := cmd.(*exec.Cmd)
		if err := cmd.Process.Kill(); err != nil {
			slog.Error("kill failed", slog.String("id", id), slog.Any("error", err))
		} else {
			slog.Info("app killed", slog.String("id", id))
		}
		appCommands.Delete(id)
	}*/
	cmd := exec.Command("docker", "kill", "mojoapp-" + id)
	if err := cmd.Run(); err != nil {
		slog.Info("docker kill failed")
	}
	cmd = exec.Command("docker", "remove", "mojoapp-" + id)
	if err := cmd.Run(); err != nil {
		slog.Info("docker remove failed")
	}
	/*pid, err := pidof(binaryFile)
	if err != nil {
		return err
	}
	if pid != 0 {
		cmd := exec.Command("kill", strconv.Itoa(pid))
		if err := cmd.Run(); err != nil {
			return err
		}
	}*/
	cmd = exec.Command("docker", "run", "-dp", fmt.Sprintf("%d:%d", port, port), "-e", fmt.Sprintf("PORT=%d", port), "--name=mojoapp-" + id, "--memory=10m", "--cpus=0.1", "mojoapps/" + id)
	var errSb strings.Builder
        cmd.Stderr = &errSb
	if err := cmd.Start(); err != nil {
		slog.Info("docker run failed")
	}
	/*binaryFile := "app_" + id
	cmd = exec.Command("./" + binaryFile)
	cmd.Dir = dir
	cmd.Env = []string{"PORT=" + strconv.Itoa(port), "HTTP_LIB=" + lib}
	if err := cmd.Start(); err != nil {
		return err
	}
	appCommands.Store(id, cmd)
	appPorts.Store(id, port)*/
	go func() {
		if err := cmd.Wait(); err != nil {
			slog.Error("app wait failed", slog.String("id", id), slog.Any("error", err))
			fmt.Println(errSb.String())
		} else {
			slog.Info("app exited", slog.String("id", id))
		}
		//appCommands.Delete(id)
	}()
	return nil
}

func pidof(name string) (int, error) {
	cmd := exec.Command("pidof", name)
	b, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			if string(exitErr.Stderr) == "" {
				return 0, nil
			}
		}
		return 0, err
	}
	output := strings.TrimSpace(string(b))
	return strconv.Atoi(output)
}

type buildAndRunRequest struct {
	ID   string `json:"id"`
	Port int    `json:"port"`
	Code string `json:"code"`
}

type buildAndRunResponse struct {
	Success bool   `json:"success"`
	Info    string `json:"info"`
}

func buildAndRunHandler(w http.ResponseWriter, req *http.Request) {
	ctx := req.Context()
	var r buildAndRunRequest
	if err := json.NewDecoder(req.Body).Decode(&r); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if r.ID == "" {
		json.NewEncoder(w).Encode(&buildAndRunResponse{
			Success: false,
			Info:    "missing ID",
		})
		return
	}
	if r.Port == 0 {
		json.NewEncoder(w).Encode(&buildAndRunResponse{
			Success: false,
			Info:    "missing port",
		})
		return
	}
	if err := build(ctx, r.ID, "build", r.Code); err != nil {
		json.NewEncoder(w).Encode(&buildAndRunResponse{
			Success: false,
			Info:    err.Error(),
		})
		return
	}
	slog.InfoContext(ctx, "app built", slog.String("id", r.ID))
	if err := run(r.ID, "build", r.Port, "../libhttpsrv.so"); err != nil {
		json.NewEncoder(w).Encode(&buildAndRunResponse{
			Success: false,
			Info:    err.Error(),
		})
		return
	}
	slog.InfoContext(ctx, "app run", slog.String("id", r.ID), slog.Int("run", r.Port))
	json.NewEncoder(w).Encode(&buildAndRunResponse{
		Success: true,
	})
}

func proxyHandler(w http.ResponseWriter, req *http.Request) {
	ctx := req.Context()
	path := req.URL.Path
	i := strings.Index(path[1:], "/")
	if i == -1 {
		http.Error(w, "ill-formed path", http.StatusBadRequest)
		return
	}
	id := path[1 : i+1]
	var port int
	if err := db.QueryRowContext(ctx, `SELECT port FROM mojo_app_ports WHERE id = $1`, id).Scan(&port); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			http.Error(w, err.Error(), http.StatusNotFound)
		} else {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		}
		return
	}
	// port, ok := appPorts.Load(id)
	// if !ok {
	// 	slog.ErrorContext(ctx, "unknown ID", slog.String("id", id))
	// 	http.Error(w, "unknown ID", http.StatusBadRequest)
	// 	return
	// }
	path = path[i+1:]
	url := fmt.Sprintf("http://localhost:%d%s?%s", port, path, req.URL.RawQuery)
	slog.InfoContext(ctx, "redirecting", slog.String("url", url))
	preq, err := http.NewRequestWithContext(ctx, req.Method, url, req.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	cl := http.Client{Timeout: 5 * time.Second}
	resp, err := cl.Do(preq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func main() {
	var err error
	db, err = sql.Open("postgres", os.Getenv("DB_DSN"))
	if err != nil {
		slog.Error("failed to connect to database")
		os.Exit(1)
	}
	if err := db.Ping(); err != nil {
		slog.Error("failed to ping database")
		os.Exit(1)
	}
	go func() {
		var mux http.ServeMux
		mux.HandleFunc("POST /build_and_run", buildAndRunHandler)
		buildServer := http.Server{
			Addr:    ":" + os.Getenv("BUILD_PORT"),
			Handler: &mux,
		}
		slog.Info("build server listening", slog.String("address", buildServer.Addr))
		if err := buildServer.ListenAndServe(); err != http.ErrServerClosed {
			slog.Error("server failed to start", slog.Any("error", err))
			os.Exit(1)
		}
	}()
	var mux http.ServeMux
	mux.HandleFunc("/", proxyHandler)
	proxyServer := http.Server{
		Addr:    ":" + os.Getenv("PROXY_PORT"),
		Handler: &mux,
	}
	slog.Info("proxy server listening", slog.String("address", proxyServer.Addr))
	if err := proxyServer.ListenAndServe(); err != http.ErrServerClosed {
		slog.Error("server failed to start", slog.Any("error", err))
		os.Exit(1)
	}
}

// func xmain() {
// 	f, err := os.Open("app.mojo")
// 	if err != nil {
// 		fmt.Fprintln(os.Stderr, err)
// 		os.Exit(1)
// 	}
// 	defer f.Close()
// 	code, err := io.ReadAll(f)
// 	if err != nil {
// 		fmt.Fprintln(os.Stderr, err)
// 		os.Exit(1)
// 	}
// 	if err := build(context.Background(), "1234", "build", string(code)); err != nil {
// 		fmt.Fprintln(os.Stderr, "build failed:", err)
// 		os.Exit(1)
// 	}
// 	if err := run("1234", "build", 8080, "../libhttpsrv.dylib"); err != nil {
// 		fmt.Fprintln(os.Stderr, "run failed:", err)
// 		os.Exit(1)
// 	}
// }
