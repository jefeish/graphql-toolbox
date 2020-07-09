var { graphql } = require('graphql');
var fs = require('fs');
var introspectionQuery = "query { __schema { types { name kind description fields { name } } } }"

var schema = graphql.utilities.buildClientSchema(introspectionQuery)
