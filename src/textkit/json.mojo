from utils import Variant
from collections import List, Dict, Optional

@value
struct JSONObject:
    var dict: Dict[String, Variant[Int, String, Bool, JSONObject, JSONArray]]

@value
struct JSONArray:
	var array: List[Variant[Int, String, Bool, JSONObject, JSONArray]]

fn parse_json_object() -> JSONObject:
    var dict = Dict[String, Variant[Int, String, Bool, JSONObject, JSONArray]]()
    return JSONObject(dict)
