library(igraph)

## without plot boundaries
x_cord <- rnorm(100) * 100
y_cord <- rnorm(100) * 100
data <- data.frame(x_cord,y_cord)
head(data)

dist <- as.matrix(dist(data))
nt_exp <- function(d, lambda) {
  prob <- exp(-lambda * dist)
  DM <- rbinom(length(prob), size = 1, prob =  prob) #the problem with stochasticity is the network becomes directional
  DM <- matrix(DM, nrow = nrow(dist), ncol = ncol(dist))
  DM[lower.tri(DM)] <- (t(DM)[lower.tri(DM)] == 1)
  diag(DM) = 0
  I <- diag(1, nrow=nrow(dist), ncol=ncol(dist))
  D <- sapply(1:nrow(dist), function(z) DM[,z]/(z+1))
  inv <- solve(I-D)

  x_cord <- function(x) data$x_cord[x]
  y_cord <- function(x) data$y_cord[x]
  cmtsize <- function(x) length(which(inv[,x]!=0))
  comp <- function(x) which(inv[,x]!=0)[1]
  g <- graph.adjacency(DM)
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



  edg_from <- function(x) replicate(length(which(DM[,x]!=0)),x)
  edg_to <- function(x) which(DM[,x]!=0)
  X_cord_from <- function(x) replicate(length(edg_from(x)), data$x_cord[x])
  Y_cord_from <- function(x) replicate(length(edg_from(x)), data$y_cord[x])
  X_cord_to <- function(x) data$x_cord[which(DM[,x]!=0)]
  Y_cord_to <- function(x) data$y_cord[which(DM[,x]!=0)]

  edg_f <- list()
  N <- nrow(dist)
  for (i in 1:N) {
    edg_f[[i]] = data.frame(edg_from = edg_from(i), edg_to = edg_to(i), X_cord_from = X_cord_from(i), Y_cord_from = Y_cord_from(i), X_cord_to = X_cord_to(i), Y_cord_to = Y_cord_to(i))
  }

  edges <- do.call(rbind, edg_f)

  id <- c(1:nrow(dist))

  tt <- function(x) length(which(inv[,x]!=0))
  compartment_size <- sapply(1:nrow(dist), tt)
  zz <- function(x) which(inv[,x]!=0)[1] #this gives the first node of each compartment as a representative of the compartment label
  compartment <- sapply(1:nrow(dist), zz)

  vertices <- data.frame(id, compartment, compartment_size)
  #vertices <- data.frame(id, cmtsize)
  for_compsizefreq <- unique(vertices[,c(2,3)])
  #compsize <- for_compsizefreq$cmtsize
  #compsize_freq <- table(compsize)

  #compartment_size_freq <- table(cmtsize)
  return(list(nodes = nodeproperties, edges = edges, compartments_table = table(for_compsizefreq)))
}
