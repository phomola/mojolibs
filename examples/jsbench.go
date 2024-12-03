package main

import (
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"
)

func main() {
	const cycles = 200
	var wg sync.WaitGroup
	start := time.Now()
	for i := 0; i < cycles; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			resp, err := http.Get(fmt.Sprintf("http://localhost:8080/%d", i))
			if err != nil {
				panic(err)
			}
			defer resp.Body.Close()
			b, err := io.ReadAll(resp.Body)
			if err != nil {
				panic(err)
			}
			fmt.Printf("%s\n", b)
		}()
	}
	wg.Wait()
	elapsed := time.Since(start)
	fmt.Println(elapsed, cycles/elapsed.Seconds())
}
