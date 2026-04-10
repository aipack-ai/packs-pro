
# When To Use this file

Include this file to understand the Inter Process Communication payload when it use the JoQL format, for example in a CRUD like JSON-RPC API. This is particulary used for API that expose a Json API to access a database model. 

# JOQL

**JOQL** is a Normative approach on top of JSON-RPC 2.0 to further define remote query calls. (see [json-rpc quick intro](json-rpc-intro)).

**JOQL** defines the following conventions:

- **Method Names** for Query Calls (read) and Muting Calls (write).
- **Query Call parameters** to filter, include, and order result.
- **Muting Call parameters** to express data change instructions.
- **Response result** data format based on Query and Muting calls.
- **Response error** format based on JSON-RPC 2.0 base error codes and application extension scheme.

JOQL follows the **ModQL** (Model Query Language) scheme, described below as `$includes`, `$filters`, `$orderBy`, `$limit`, `$offset`.

[GitHub: modql/joql-spec](https://github.com/modql/joql-spec)

## Method Names

At the high level, there are two types of RPC Calls

- **Query Methods** - Those calls do not change the data but only return the requested datasets. This specification normalized advanced filtering and inclusion schemes.
- **Muting Methods** - Those calls focus on changing a particular data. While it might return the data changed at some granularity, it should not include the same query capability as the first one.

All JSON-RPC methods will be structured with the following snake case format `[entity_model]_[verb]`.

For example, for an entity `Project`:

- `project_get` - Get a single project for a given `id` (the PK of the Project entity)
- `project_list` - Return the list of project entities based on a `#filters` (criteria) and `#includes` (what to include for reach project item)
- `project_create` - Create the project, and if there is some unicity conflict, it will fail and return an error.
- `project_update` - This will update an existing project.
- `project_delete` - Delete a project for a given id.
- `project_save` - (should be rare) The verb `save` will be used for `upsert` capability. It should be exposed only if strictly required by the application model.

> NON-GOAL - By design, this service protocol does NOT require the service to support complete collection management "a-la-ORM" like Hibernate or such. While it is an attractive engineering problem to solve, it often puts too much complexity on one side of the system and ends up counterproductive for both sides. So, to add a `Ticket` to a `Project`, the method is `ticket_create` with the params `{projectId: ...}`.

Here are the normative method verbs (in the examples below, the `jsonrpc` and `id` are omitted for brevity)

#### Query Method

| verb       | meaning                                                                                                      | example                                                                                                   |
| ---------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `get`      | Get only one item by PK id (`result.data` will be the entity project. json-rpc error if not found/no access) | `project_get` with params: `{id: 123 }`                                                                   |
| `list`     | List cases based on some (`result.data` always array)                                                        | `project_list` with params: `{"$filters": {title:  {$startsWith = "cool"} }`                              |
| `first`    | Params like list, return like get (`result.data` null if nothing found)                                      | `project_first` with params: `{"$filters": {title:  "title 1" }`                                          |
| `[custom]` | Domain specific verb                                                                                         | `project_live_list` (e.g., return projects that are beeing edited or worked at this specific request time) |

Note - `..._get` methods' params are fixed for their PK only. If another way is needed to get an entity, for example, get user by username, another `user_get_by_username` method with params `{username: "..."}` should be exposed.

#### Muting Methods

| verb       | meaning                                                    | example                                                                                                               |
| ---------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `create`   | Create the new given entity                                | `project_create` with params: `{data: {title: "title 1"}}`                                                            |
| `update`   | Update the new given entity                                | `project_update` with params: `{id: 123, data: {title: "title 1 updated"}}`                                           |
| `delete`   | Update the new given entity                                | `project_delete` with params: `{id: 123}`                                                                             |
| `save`     | Upsert a new entity (only if strictly needed by app model) | `project_label_save` with params: `{projectId: 123, data: {name: "ImportantFlag", color: "red"}}`                      |
| `[custom]` | Domain specific verb                                       | `project_import` with params: `{"projectId": 123}` (here can prefix property `id` with `project` as not a crud method) |

## Query Call Structure

A query call is typically done on the top model entity implied from their method name (e.g., `project_list`, `todo_list`).

- `$includes` - Query methods might allow specifying what should be returned in the response relative to the main query entity. This is done with the `params` property `$includes`.
- `$filters` - Query such as `list...` and `...first` should allow a way to filter what needs to be returned, which is expressed with the `params` property `$filters`.
- `$orderBy` - Allows ordering the list of entities by some of its properties. Using a property name like `"title"` will order ascending, and prefixing it with `!` will make it descending.
- `$limit` - Limit the number of entities being returned (only apply to the top-level entities)
- `$offset` - Skip that many entities before beginning to return the entity list.

### `$includes`

`$includes` is a way to specify what needs to be included in the response.

- The simplest way is to have `$includes: {propertyName: true}` which will include the property name in the response.
- When the `propertyName` value is an object, then doing `$includes: {propertyName: true}` will include the default properties of this entity model (typically `id`, `name`)
- By convention, `$include` keys started with `_` represents a group of properties. For example `_defaults` represents the default properties of the entity. In other words, `_...` are shortcut group properties to not have to specify them one by one. Those are application specifics.
- When the `propertyName` value is an object, we can become more precise. For example, for a `project_list` method, `$includes` could look like:

```ts
$includes: {
    // will include the default properties of each Project (same as $includes.project: true)
    _defaults: true,
    // will includes the timestamps cid, ctime, mid, mtime
    _timestamps: true,

    // include description part of the return
    description: true,

    tickets: { // include the related tickets
      _defaults: true, // this may include .id and .title
      description: true, // this will add .description
    },

    workspace: true, // can even include container if the model layer allows it.
}
```

### `$filters`

The `$filters` main params property allows to specify filters to be apply to the query call.

For example, the following request will list all of the tickets for which name contains 'safari'

- Filter property, can be exact match, such as `title: "safari"` in this case it will exact match.
- Or can have one or more [Conditional Operators](#conditional-operators) commands like `title: {"$contains": "safari", "startsWith": "compat"}` which will match only tickets that have their title match

```js
{
    jsonrpc: "2.0",
    method: "ticket_list",
    params: {
        // narrow the targeted entity result set
        $filters: {
            projectId: 123,
            // return tickets where .name contains 'safari'
            name: {$contains: "safari"}
        },

        // define what to return for what has been matched by a targeted entity
        $includes: {
            "id": true, // returns the ticket.id
            "title": true, // returns the ticket.name
         },
        $orderBy: "!ctime",
    },
    id: null
}
```

## Query Calls Example

The `list` and `first` query are structured the following way.

All data (array or single object) of all query calls are always in `result.data`.

For example, list projects given some filters and specifying what to include.

```js
{
    jsonrpc: "2.0",
    method: "project_list",
    params: {
        // narrow the targeted entity result set
        $filters: {
            // return projects where .name contains 'safari'
            name: {$contains: "safari"}
        },

        // define what to return for what has been matched by a targeted entity
        $includes: {
            "id": true, // returns the project.id
            "name": true, // returns the project.name

            // will include tickets (joined entity), with the following property for each item
            tickets: {
                // cid, ctime, mid, mtime (starts with _ because not a direct property, group of properties)
                _timestamps: true,

                // default to give only "label.name" in this case. can do {timestamp: true, color: true}
                labels: true,

                // Advanced sub filtering (might be omitted by implementation)
                $orderBy: ["!ctime"],

                $filters: {
                    "title": {$contains: "important"},
                },
            },

            owner: {id: false, fullName: true, username: true}
         },
        $orderBy: "!ctime",
    },
    id: null
}
```

The json-rpc response will look like this:

```js
{
    // REQUIRED and must be exactly "2.0"
    jsonrpc: "2.0",
    result: {
        data: [
            // project entity
            {
                name: "Safari Update Project",
                tickets: [
                    {
                        title: "This is an important ticket",
                        cid: ...,
                        ctime: ...,
                        cid: ...,
                        mtime: ...,
                        labels: [{name: "..."}, {name: "..."}]
                    },

                ],
                owner: {....}
            },
            // project entity
            { ... }
        ],
        // advanced, when pagination is supported
        $orderBy: "!mtime", // order by modification time descendant (most recent first)
        $limit: 100, // only get the 100 most recent
    },

    id: "id from request"

}
```

> Note - The requested data, here the list of projects, is always returned in the `result.data` property.
> This allows to have other top level property down the road, such as `result.meta` to get `pagination` token or such meta data.

## Muting Call Example

When calling `create` or `update` muting calls, the convention is that the `params.data` contain the patch entity to be created or updated.

For example, a **create project** call would look like:

```js
{
    jsonrpc: "2.0",
    method: "project_create",
    params: {
        data: {
            title: "My first project"
        }
    },
    id: null
}
```

For example, a **update project** call would look like:

```js
{
    jsonrpc: "2.0",
    method: "project_update",
    params: {
        id: 123,
        data: {
            title: "My first project"
        }
    },
    id: null
}
```

For example, a **delete project** call would look like:

```js
{
    jsonrpc: "2.0",
    method: "project_delete",
    params: {
        id: 123
    },
    id: null
}
```

A list project with some criterias

```js
{
    jsonrpc: "2.0",
    method: "listProjects",
    params: {
        $fitlers: {
            name:
        }
    },
    id: null
}

```

Now, to create a ticket for this project (let's say that this projectId is `123`)

```ts
{
    jsonrpc: "2.0",
    method: "ticket_create",
    params: {
        sendNotification: true, // just example of top level
        data: { // TicketCreate
            projectId: number,
            title: "My first ticket",
            attributes_add: { // assuming ticket have a "attributes" jsonb like property and need to add a key/value to it
                "some_attribute_name": "Some value"
            }
        }
    },
    id: null
}
```

```js
{
    jsonrpc: "2.0",
    method: "ticket_update",
    params: {
        id: 1111,
        data: { // TicketUpdate
            title: "My first project"
        }
    },
    id: null
}
```

Example of possible 'schema' for `TicketCreate` or `TicketUpdate` `params.data` types.

```ts
interface TicketCreate {
  title: string;
  open: boolean;
  projectId: number;
}

interface TicketUpdate {
  title: string;
  open: boolean;
}
```

## Conditional Operators

Filters and Includes allow to express conditional rules base on a `{property: {operator1: value1, operator2: value2}}` scheme. The following table shows the list of possible operators.

### String Operators

| Operator            | Meaning                                         | Example                                                  |
| ------------------- | ----------------------------------------------- | -------------------------------------------------------- |
| `$eq`               | Exact match with one value                      | `{name: {"$eq": "Jon Doe"}}` same as `{name: "Jon Doe"}` |
| `$in`               | Exact match with within a list of values (or)   | `{name: {"$in": ["Alice", "Jon Doe"]}}`                  |
| `$not`              | Exclude any exact match                         | `{name: {"$not": "Jon Doe"}}`                            |
| `$notIn`            | Exclude any exact withing a list                | `{name: {"$notIn": ["Jon Doe"]}}`                        |
| `$contains`         | For string, does a contains                     | `{name: {"$contains": "Doe"}}`                           |
| `$containsAny`      | For string, match if contained in any of items  | `{name: {"$containsAny": ["Doe", "Ali"]}}`               |
| `$containsAll`      | For string, match if all items are in the src   | `{name: {"$containsAll": ["Hello", "World"]}}`           |
| `$notContains`      | Does not contain                                | `{name: {"$notContains": "Doe"}}`                        |
| `$notContainsAny`   | Does not call any of (none is contained)        | `{name: {"$notContainsAny": ["Doe", "Ali"]}}`            |
| `$startsWith`       | For string, does a startsWith                   | `{name: {"$startsWith": "Jon"}}`                         |
| `$startsWithAny`    | For string, match if startsWith in any of items | `{name: {"$startsWithAny": ["Jon", "Al"]}}`              |
| `$notStartsWith`    | Does not start with                             | `{name: {"$notStartsWith": "Jon"}}`                      |
| `$notStartsWithAny` | Does not start with any of the items            | `{name: {"$notStartsWithAny": ["Jon", "Al"]}}`           |
| `$endsWith`         | For string, does and end with                   | `{name: {"$endsWithAny": "Doe"}}`                        |
| `$endsWithAny`      | For string, does a contains (or)                | `{name: {"$endsWithAny": ["Doe", "ice"]}}`               |
| `$notEndsWith`      | Does not end with                               | `{name: {"$notEndsWithAny": "Doe"}}`                     |
| `$notEndsWithAny`   | Does not end with any of the items              | `{name: {"$notEndsWithAny": ["Doe", "ice"]}}`            |
| `$lt`               | Lesser Than                                     | `{name: {"$lt": "C"}}`                                   |
| `$lte`              | Lesser Than or =                                | `{name: {"$lte": "C"}}`                                  |
| `$gt`               | Greater Than                                    | `{name: {"$gt": "J"}}`                                   |
| `$gte`              | Greater Than or =                               | `{name: {"$gte": "J"}}`                                  |
| `$null`             | If the value is null                            | `{name: {"$null": true}}`                                |

### Number Operators

| Operator | Meaning                                       | Example                                  |
| -------- | --------------------------------------------- | ---------------------------------------- |
| `$eq`    | Exact match with one value                    | `{age: {"$eq": 24}}` same as `{age: 24}` |
| `$not`   | Exclude any exact match                       | `{age: {"$not": 24}}`                    |
| `$in`    | Exact match with within a list of values (or) | `{age: {"$in": [23, 24]}}`               |
| `$notIn` | Exclude any exact withing a list              | `{age: {"$notIn": [24]}}`                |
| `$lt`    | Lesser Than                                   | `{age: {"$lt": 30}}`                     |
| `$lte`   | Lesser Than or =                              | `{age: {"$lte": 30}}`                    |
| `$gt`    | Greater Than                                  | `{age: {"$gt": 30}}`                     |
| `$gte`   | Greater Than or =                             | `{age: {"$gte": 30}}`                    |

### Boolean Operators

| Operator | Meaning                    | Example                                      |
| -------- | -------------------------- | -------------------------------------------- |
| `$eq`    | Exact match with one value | `{dev: {"$eq": true}}` same as `{dev: true}` |
| `$not`   | Exclude any exact match    | `{dev: {"$not": false}}`                     |

### String Array Operators

| Operator              | Meaning                                          | Example                                |
| --------------------- | ------------------------------------------------ | -------------------------------------- |
| `String Operators...` | All String Operators applying to one of the item | `{tags: "P1"}`                         |
| `$has`                | Matching if value has all of the items           | `{tags: {"$has": ["P1", "Feature"]} }` |

### Naming convention

The operator sub-parts can be described as below:

- `not` is a **prefix** when we want to express the negation of another operator. camelCase follows the `not` prefix.
- `in` is a **suffix** when an operator can take a list of items. It means it will succeed if one of the item match.

> While those operator notations are vaguely inspired by the [mongodb syntax](https://docs.mongodb.com/manual/reference/operator/query/#std-label-query-selectors), they are designed to be more limited and structured (e.g., avoid union types when possible), and not for familiarity.

## Error Codes

The error codes from and including -32768 to -32000 are reserved for pre-defined errors.
Any code within this range but not defined explicitly below is reserved for future use. The error codes are nearly the same as those suggested for XML-RPC at the following url: http://xmlrpc-epi.sourceforge.net/specs/rfc.fault_codes.php

### JSON-RPC errors

| code   | message (enum style)         | meaning                                                                                   |
| ------ | ---------------------------- | ----------------------------------------------------------------------------------------- |
| -32700 | PARSE_NOT_VALID_JSON         | Not a valid JSON                                                                          |
| -32701 | PARSE_UNSUPPORTED_ENCODING   | parse error. unsupported encoding                                                         |
| -32702 | PARSE_INVALID_CHAR_ENCONDING | parse error. invalid character for encoding                                               |
| -32600 | JSON_RPC_INVALID_FORMAT      | The JSON sent is not a valid Request object (no `id` or missing/invalid `jsonrpc` value). |
| -32601 | JSON_RPC_METHOD_NOT_FOUND    | The method does not exist / is not available.                                             |
| -32602 | JSON_RPC_PARAMS_INVALID      | The params is an invalid json-rpc (should be object or array)                             |
| -32603 | JSON_RPC_INTERNAL_ERROR      | Another json-rpc error happened not captured above                                        |
| -32500 | SERVICE_ERROR                | An unknown service/application error (should try to avoid)                                |

### JOQL Specific errors

| code  | message (enum style)      | meaning                                                                                                                        |
| ----- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| -2000 | JOQL_PARAMS_NOT_OBJECT    | In JOQL `params` must but be an object (cannot be an array)                                                                    |
| -2001 | JOQL_PARAMS_QUERY_INVALID | For Query calls only `$includes` `$filters` and `$pagination` and `$orderBy` are allowed for now (this can be extended by app) |

### Application errors

| code      | message (enum style) | meaning                                                                                 |
| --------- | -------------------- | --------------------------------------------------------------------------------------- |
| 1000-1099 | AUTH\_...            | Authentication error (missing header, expired, ...)                                     |
| 1100-1199 | ACCESS\_...          | Access/Privileges Errors                                                                |
| 3000-...  | ...\_....            | Other Application Errors                                                                |
| 5000      | INVALID_METHOD_NAME  | Invalid method name                                                                     |
| 5010      | INVALID_PARAMS       | Invalid params for the method name (list of error are in errors.data: {desc: string}[]) |

## Key data types

- All date/time will be of type string with the format **ISO 8601** `YYYY-MM-DDTHH:mm:ss.sssZ`

## License

[Apache-2.0](LICENSE-APACHE) OR [MIT](LICENSE-MIT)

Copyright (c) 2023 BriteSnow, Inc
