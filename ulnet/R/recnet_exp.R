recnet_exp <- function(d, lambda, xmin, xmax, ymin, ymax) {
  #based on user-defined threshold distance, d, to create an adjancency matrix of nodes
  prob <- exp(-lambda * dist)
  DM <- rbinom(length(prob), size = 1, prob =  prob)
  DM <- matrix(DM, nrow = nrow(dist), ncol = ncol(dist))
  DM[lower.tri(DM)] <- (t(DM)[lower.tri(DM)] == 1)
  diag(DM) = 0
  I <- diag(1, nrow=nrow(dist), ncol=ncol(dist))

  #the application of the fundamental matrix of Markov Chain to generate information of comparments
  D <- matrix(0, nrow=nrow(dist), ncol = ncol(dist))
  D <- sapply(1:nrow(dist), function(z) DM[,z]/(z+1))
  inv <- solve(I-D)

  # collect node properties of the network
  x_cord <- function(x) data$x_cord[x] #x-coordinates of nodes
  y_cord <- function(x) data$y_cord[x] #y-coordinates of nodes
  cmtsize <- function(x) length(which(inv[,x]!=0)) #compartment sizes of nodes
  comp <- function(x) which(inv[,x]!=0)[1] #compartment identities
  g <- graph.adjacency(DM) #generate a graph
  between <- function(x) betweenness(g, directed=FALSE)[x] #betweenness centralities of nodes
  close <- function(x) closeness(g, mode = "out")[x] #closeness centralities of nodes
  degree_centrality <- function(x) length(which(DM[,x]==1)) #degree centralities of nodes

  node_prop <- list()
  N <- nrow(dist)
  for (i in 1:N) {
    node_prop[[i]] = data.frame(x_cord = x_cord(i), y_cord = y_cord(i), compartment_id = comp(i), comp_size = cmtsize(i),
                                between_ct = between(i), close_ct = close(i), degree_ct = degree_centrality(i)
    )
  }
  nodeproperties <- do.call(rbind, node_prop)

  # based on user-defined threshold distance, remove nodes in comparmtnets of which distance to any of the plot margins < d

  p1 <- nodeproperties$compartment_id[which(nodeproperties$y_cord > ymax - d)]
  p2 <- nodeproperties$compartment_id[which(nodeproperties$y_cord < ymin + d)]
  p3 <- nodeproperties$compartment_id[which(nodeproperties$x_cord < xmin + d)]
  p4 <- nodeproperties$compartment_id[which(nodeproperties$x_cord > xmax - d)]

  unidt1 <- unique(p1)
  unidt2 <- unique(p2)
  unidt3 <- unique(p3)
  unidt4 <- unique(p4)
  unidt <- unique(c(unidt1, unidt2, unidt3, unidt4))

  filtered_nodes <- subset(nodeproperties, compartment_id %nin% unidt)

  # produce an edge table
  edg_from <- function(x) replicate(length(which(DM[,x]!=0)),x)
  edg_to <- function(x) which(DM[,x]!=0)
  X_cord_from <- function(x) replicate(length(edg_from(x)), data$x_cord[x])
  Y_cord_from <- function(x) replicate(length(edg_from(x)), data$y_cord[x])
  X_cord_to <- function(x) data$x_cord[which(DM[,x]!=0)]
  Y_cord_to <- function(x) data$y_cord[which(DM[,x]!=0)]
  zz <- function(x) which(inv[,x]!=0)[1]
  comp <- sapply(1:nrow(dist), zz)
  compar <- function(x) replicate(length(which(DM[,x]!=0)), comp[x])

  edg_f <- list()
  N <- nrow(dist)
  for (i in 1:N) {
    edg_f[[i]] = data.frame(edge_from = edg_from(i), edge_to = edg_to(i), X_cord_from = X_cord_from(i), Y_cord_from = Y_cord_from(i), X_cord_to = X_cord_to(i), Y_cord_to = Y_cord_to(i), compartment_id = compar(i))
  }

  edges <- do.call(rbind, edg_f)
  filtered_edges <- subset(edges, compartment_id %nin% unidt)
  filtered_edges <- filtered_edges[,c(1:6)]
  #return(filtered_edges)

  networkstats <- unique(filtered_nodes[,c(3,4)])
  compsize <- networkstats$comp_size
  compsize_freq <- table(compsize)
  return(list(nodes = filtered_nodes, edges = filtered_edges, compsize = compsize, compartments_table = table(networkstats)))
}
