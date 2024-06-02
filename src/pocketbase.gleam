import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, dict, dynamic, field, int, list, string}
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleeunit/should

pub type ListResult {
  ListResult(
    page: Int,
    per_page: Int,
    total_pages: Int,
    total_items: Int,
    items: List(Dict(String, Dynamic)),
  )
}

pub type SchemaField {
  SchemaField(
    id: String,
    name: String,
    type_: String,
    system: Bool,
    required: Bool,
    presentable: Bool,
    unique: Bool,
    options: Dict(String, Dynamic),
  )
}

pub type Pocketbase {
  Admin(
    id: String,
    created: String,
    updated: String,
    avatar: String,
    email: String,
  )
  Backup(
    id: String,
    created: String,
    updated: String,
    key: String,
    modified: String,
    size: Int,
  )
  Collection(
    id: String,
    created: String,
    updated: String,
    name: String,
    type_: String,
    schema: List(SchemaField),
    system: Bool,
    list_rule: Option(String),
    view_rule: Option(String),
    create_rule: Option(String),
    update_rule: Option(String),
    delete_rule: Option(String),
    options: Dict(String, Dynamic),
  )
  ExternalAuth(
    id: String,
    created: String,
    updated: String,
    record_id: String,
    collection_id: String,
    provider: String,
    provider_id: String,
  )
  LogRequest(
    id: String,
    created: String,
    updated: String,
    url: String,
    method: String,
    status: String,
    auth: String,
    remote_ip: String,
    user_ip: String,
    referer: String,
    user_agent: String,
    meta: Dict(String, Dynamic),
  )
  Record(
    id: String,
    created: String,
    updated: String,
    collection_id: String,
    collection_name: String,
    expand: Dict(String, Dynamic),
  )
}

pub fn record_from_dict(data: Dict(String, Dynamic)) -> Pocketbase {
  Record(
    id: data
      |> dict.get("id")
      |> result.unwrap(dynamic.from("id"))
      |> string
      |> result.unwrap("id"),
    created: data
      |> dict.get("created")
      |> result.unwrap(dynamic.from("created"))
      |> string
      |> result.unwrap("created"),
    updated: data
      |> dict.get("updated")
      |> result.unwrap(dynamic.from("updated"))
      |> string
      |> result.unwrap("updated"),
    collection_id: data
      |> dict.get("collectionId")
      |> result.unwrap(dynamic.from("collectionId"))
      |> string
      |> result.unwrap("collectionId"),
    collection_name: data
      |> dict.get("collectionName")
      |> result.unwrap(dynamic.from("collectionName"))
      |> string
      |> result.unwrap("collectionName"),
    expand: data
      |> dict.drop([
        "id", "created", "updated", "collectionId", "collectionName",
      ]),
  )
}

pub fn list_result_from_json(
  json_string: String,
) -> Result(ListResult, json.DecodeError) {
  let decoder =
    dynamic.decode5(
      ListResult,
      field("page", of: int),
      field("perPage", of: int),
      field("totalItems", of: int),
      field("totalPages", of: int),
      field("items", of: list(dict(string, dynamic))),
    )
  json.decode(from: json_string, using: decoder)
}

pub fn send_request() {
  let assert Ok(req) =
    request.to("http://127.0.0.1:8090/api/collections/tasks/records")
  use resp <- result.try(httpc.send(req))
  resp.status
  |> should.equal(200)
  Ok(resp)
}

pub fn main() {
  io.println("Hello from pocketbase!")
  let assert Ok(r) = send_request()
  // io.debug(r)
  let assert Ok(r) = list_result_from_json(r.body)
  // io.debug(r)
  let items =
    r.items
    |> list.map(fn(i) { record_from_dict(i) })
  io.debug(items)
}
