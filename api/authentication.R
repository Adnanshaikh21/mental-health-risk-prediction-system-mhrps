library(digest)

authenticate_user <- function(username, password) {
  users <- data.frame(
    username = c("educator", "counselor", "admin"),
    password = sapply(c("educator123", "counselor123", "admin123"), function(p) digest(p, algo = "sha256")) # nolint
  )
  user <- users[users$username == username, ]
  if (nrow(user) == 0) return(FALSE)
  return(user$password == digest(password, algo = "sha256")) # nolint
}