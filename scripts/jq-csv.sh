# jq -r \
#  '.data.organization.repositories.nodes[] |
#   { nameWithOwner: .nameWithOwner, edges: .collaborators.edges[]?} | 
#   [.nameWithOwner, .edges.node.name, .edges.node.login, .edges.permission] |
#   @csv' $1

jq -r \
 '.data.organization.repository |
  { nameWithOwner: .nameWithOwner, edges: .collaborators.edges[]?} | 
  [.nameWithOwner, .edges.node.name, .edges.node.login, .edges.permission] |
  @csv' $1