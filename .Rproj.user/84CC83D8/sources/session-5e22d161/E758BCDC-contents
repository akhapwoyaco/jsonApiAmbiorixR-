#
library(data.table)
library(nycflights13)
library(DBI)
library(RSQLite)
library(jsonlite)
library(ambiorix)

# Configuration
config <- list(
  port = 3000,
  db_path = "flights.db",
  log_path = "api.log",
  rate_limit = 100,  # requests per minute
  cache_ttl = 300,   # cache timeout in seconds
  auth_token = "dev-token-123"  # authentication
)

# initialize logger
log_setup <- function(){
  logger::log_threshold(logger::DEBUG)
  logger::log_appender(logger::appender_file(config$log_path))
}

# Part 1: Data Processing
# Load and transform the flights dataset
process_flights_data <- function() {
  
  logger::log_info("Starting data processing ... ")
  
  # Convert flights data to data.table
  flights_dt <- as.data.table(nycflights13::flights)
  logger::log_debug(sprintf("Flights data loaded with %d rows.", nrow(flights_dt)))
  
  # Add unique ID for each flight
  flights_dt[,ID := .I]
  
  # Add delayed column (TRUE if delay > 15 minutes)
  flights_dt[, is_delayed := dep_delay > 15]
  
  # Calculate average departure delay by carrier
  avg_delays <- flights_dt[, .(avg_delay = mean(dep_delay, na.rm = TRUE)), by = carrier]
  
  # Find top destinations by flight count
  top_destinations <- flights_dt[, .N, by = dest][order(-N)]
  
  logger::log_info("Ending data processing ... ")
  
  return(list(
    flights = flights_dt,
    avg_delays = avg_delays,
    top_destinations = top_destinations
  ))
}
#' 
# Initialize SQLite database
setup_database <- function(processed_data) {
  
  logger::log_info("Setting database ... ")
  
  # Ensure database file is writable
  if(file.exists(config$db_path)) {
    file.remove(config$db_path)
    logger::log_info("Removed existing database file")
  }
  
  con <- dbConnect(RSQLite::SQLite(), config$db_path)       # "flights.db")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Create flights table
  logger::log_info("Writing flights data to database")
  tryCatch({
    dbWriteTable(con, "flights", processed_data$flights, overwrite = TRUE)
    logger::log_info("Successfully wrote flights data")
  }, error = function(e) {
    logger::log_error(paste("Error writing flights data:", e$message))
    stop(e)
  })
  
  # Create indexes for better query performance
  # dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_ID ON flights(ID)")
  # dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_carrier ON flights(carrier)")
  
  logger::log_info("Setting database completed ... ")
  
}

# Database helper functions
get_db_connection <- function() {
  tryCatch({
    con <- dbConnect(RSQLite::SQLite(), config$db_path)
    if(is.null(con)){
      logger::log_error("Database connection is null")
    }
    
    return(con)
  }, error = function(e) {
    logger::log_error(paste("Database connection error:", e$message))
    stop("Database connection failed")
  })
  
}

# Error Handling
handle_error <- function(err) {
  logger::log_error(sprintf("Error: %s", err$message))
  
  list(
    error = TRUE,
    message = err$message,
    status = 500,
    timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}


# parse request body
parse_request_body <- function(req) {
  if (is.null(req$body) || req$body == "") {
    return(NULL)
  }
  
  tryCatch({
    if (is.character(req$body)) {
      return(jsonlite::fromJSON(req$body, simplifyVector = TRUE))
    } else {
      return(req$body)  # Might already be parsed
    }
  }, error = function(e) {
    logger::log_error(paste("JSON parse error:", e$message))
    return(NULL)
  })
}
#
# Part 2: API Implementation
create_app <- function() {
  app <- Ambiorix$new()
  
  # Debug log requests
  app$use(function(req, res) {
    logger::log_debug(paste("Received request:", req$method, req$path))
    return(TRUE)
  })
  
  # Basic health check that doesn't require auth
  app$get("/health", function(req, res) {
    res$json(list(status = "ok", message = "API is running"))
  })  
  
  #'   # 1. POST /flight - Create new flight
  #'   app$post(
  #'     "/flight",
  #'     # validate_request(list(body = c("year", "month", "day", "dep_time", "carrier", "flight", "origin", "dest"))),
  #'     function(req, res) {
  #'       tryCatch({
  #'         logger::log_info("POST /flight route handler called") # Add this
  #'         # logger::log_info(paste("Request body:", req$body))
  #'         # 
  #'         # # Debug log the request body
  #'         # logger::log_debug(paste("Request body:", req$body))
  #'         # 
  #'         # Safely parse JSON with error handling
  #'         if (is.null(req$body)){#} || req$body == "") {
  #'           res$status <- 400
  #'           res$json(list(error = "Empty request body"))
  #'           return(TRUE)
  #'         }
  #'         
  #'         # Use the helper function instead of inline parsing
  #'         flight_data <- parse_request_body(req)
  #'         
  #'         if (is.null(flight_data)) {
  #'           res$status <- 400
  #'           res$json(list(error = "Invalid or empty request body"))
  #'           return(TRUE)
  #'         }
  #'         
  #'         # parse json
  #'         # flight_data <- tryCatch({
  #'         #   fromJSON(req$body, simplifyVector = TRUE)
  #'         # }, error = function(e) {
  #'         #   logger::log_error(paste("JSON parse error:", e$message))
  #'         #   res$status <- 400
  #'         #   res$json(list(error = "Invalid JSON in request body"))
  #'         #   return(NULL)
  #'         # })
  #'         
  #'         # if (is.null(flight_data)) return()
  #'         
  #'         logger::log_debug(paste("Parsed flight_data:", str(flight_data)))
  #'         
  #'         con <- get_db_connection()
  #'         on.exit(dbDisconnect(con), add = TRUE)
  #'         
  #'         
  #'         
  #'         # Get the last flight id and increment it
  #'         last_flight_id_result <- dbGetQuery(con, "SELECT MAX(ID) FROM flights")
  #'         last_flight_id <- last_flight_id_result[[1, 1]] # Extract the value
  #'         
  #'         if (is.null(last_flight_id)) {
  #'           flight_data$ID <- 1 # If no previous records, start with 1
  #'         } else {
  #'           flight_data$ID <- last_flight_id + 1
  #'         }
  #'         
  #'         # flight_data <- fromJSON(req$body)
  #'         # flight_data$ID <- uuid::UUIDgenerate()
  #'         
  #'         # Convert to data frame first
  #'         flight_df <- as.data.frame(flight_data, stringsAsFactors = FALSE)
  #'         # Log the structure before writing
  #'         logger::log_debug(paste("Flight data structure:", 
  #'                                 paste(names(flight_df), collapse=", ")))
  #'         # Log the structure we're trying to write
  #'         logger::log_debug(paste("Writing flight data with columns:", 
  #'                                 paste(names(flight_df), collapse=", ")))
  #'         
  #'         # Get existing table structure to ensure compatibility
  #'         table_info <- dbGetQuery(con, "PRAGMA table_info(flights)")
  #'         if (nrow(table_info) > 0) {
  #'           logger::log_debug(paste("Existing table columns:", 
  #'                                   paste(table_info$name, collapse=", ")))
  #'         }
  #'         # 
  #'         dbWriteTable(con, "flights", flight_df, append = TRUE)
  #'         
  #'         logger::log_info(sprintf("Created flight: %s", flight_data$ID))
  #'         
  #'         res$json(list(
  #'           success = TRUE,
  #'           ID = flight_data$ID,
  #'           message = "Flight created successfully"
  #'         ))
  #'       }, error = function(err) {
  #'         logger::log_error(paste("Error creating flight:", err$message))
  #'         logger::log_error(paste("Error call:", deparse(err$call)))
  #'         res$status <- 500
  #'         res$json(handle_error(err))
  #'       })
  #'     })
  
  # 2. GET /flight/:id - Get flight details
  app$get("/flight/:id", function(req, res) {
    print(paste("GET /flight/:id called with id:", req$params$id))
    print(paste("GET /flight/:id called with id:", unlist(req$params$id)))
    logger::log_debug(paste("GET /flight/:id called with id:", req$params$id))
    tryCatch({
      logger::log_debug(paste("GET /flight/:id called with id:", req$params$id))
      logger::log_debug(paste("Request parameters:", paste(names(req$params), req$params, collapse = ", ")))
      
      
      con <- get_db_connection()
      logger::log_debug(paste("Database connection established:", !is.null(con)))
      on.exit(dbDisconnect(con), add = TRUE)
      
      query <- "SELECT * FROM flights WHERE ID = ?"
      logger::log_debug(paste("Executing SQL query:", query, "with params:", req$params$id))
      
      
      flight <- dbGetQuery(
        con,
        "SELECT * FROM flights WHERE ID = ?",
        params = unlist(req$params$id) ###
      )
      
      logger::log_debug(paste("Query result:", nrow(flight), "rows"))
      
      if (nrow(flight) == 0) {
        res$status <- 404
        res$json(list(error = "Flight not found"))
        return()
      }
      
      logger::log_info("GET /flight/:id completed successfully")
      res$json(flight)
      
      
    }, error = function(err) {
      logger::log_error(paste("Error in GET /flight/:id:", err$message))
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  
  # 3. GET /check-delay/:id - Check if flight was delayed
  app$get("/check-delay/:id", function(req, res) {
    tryCatch({
      con <- get_db_connection()
      on.exit(dbDisconnect(con), add = TRUE)
      
      delay_status <- dbGetQuery(
        con,
        "SELECT is_delayed FROM flights WHERE ID = ?",
        params = unlist(req$params$id) ###
      )
      
      if (nrow(delay_status) == 0) {
        res$status <- 404
        res$json(list(error = "Flight not found"))
        return()
      }
      
      res$json(list(
        ID = req$params$id,
        is_delayed = delay_status$is_delayed
      ))
    }, error = function(err) {
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  #
  # 4. GET /avg-dep-delay - Get average delay by airline
  app$get("/avg-dep-delay/:id", function(req, res) {
    tryCatch({
      con <- get_db_connection()
      on.exit(dbDisconnect(con), add = TRUE)
      
      airline <- req$params$id
      
      if (!is.null(airline)) {
        query <- "SELECT carrier, AVG(dep_delay) AS avg_delay FROM flights WHERE carrier = ?"
        params <- list(airline)
        delays <- dbGetQuery(con, query, params = params)
        
        if (nrow(delays) == 0) {
          res$status <- 404
          res$json(list(error = "Carrier not found"))
          return()
        }
        
      } else {
        #This else statement will not be used, because :id is required.
        query <- "SELECT carrier, AVG(dep_delay) AS avg_delay FROM flights GROUP BY carrier"
        delays <- dbGetQuery(con, query)
      }
      
      res$json(delays)
    }, error = function(err) {
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  #
  # 5. GET /top-destinations/:n - Get top n destinations
  app$get("/top-destinations/:n", function(req, res) {
    tryCatch({
      con <- get_db_connection()
      on.exit(dbDisconnect(con), add = TRUE)
      
      n <- as.integer(req$params$n)
      
      if (is.na(n) || n <= 0) {
        res$status <- 400
        res$json(list(error = "Invalid number of destinations requested"))
        return()
      }
      
      top_dest <- dbGetQuery(
        con,
        "SELECT dest, COUNT(*) as flight_count
           FROM flights
           GROUP BY dest
           ORDER BY flight_count DESC
           LIMIT ?",
        params = list(n)
      )
      
      res$json(top_dest)
    }, error = function(err) {
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  
  # 6. PUT /flights/:id - Update flight details
  app$put("/flights/:id", function(req, res) {
    tryCatch({
      
      logger::log_info("PUT STARTS")
      
      data <- req$body[["rook.input"]]
      data <- data$read_lines()
      mmmm = jsonlite::fromJSON(data)
      
      # print(mmmm)

      logger::log_info(mmmm)
      
      # Parse JSON safely
      flight_data <- tryCatch({
        #
        data <- req$body[["rook.input"]]
        data <- data$read_lines()
        jsonlite::fromJSON(data)
        #
        # lapply(my_list, function(x) as.data.frame(fromJSON(x))) |>
        #   dplyr::bind_rows()
        # jsonlite::fromJSON(req$body, simplifyVector = TRUE)
      }, error = function(e) {
        logger::log_error(paste("JSON parse error:", e$message))
        res$status <- 400
        res$json(list(error = paste("Invalid JSON in request body:", e$message)))
        return(NULL)
      })

      if (is.null(flight_data)) return(TRUE)
      
      con <- get_db_connection()
      on.exit(dbDisconnect(con))
      
      # Check if flight exists
      exists <- dbGetQuery(
        con,
        "SELECT 1 FROM flights WHERE ID = ?",
        params = list(req$params$id)
      )
      
      logger::log_info("PUT EXISTS")
      
      if (nrow(exists) == 0) {
        res$status <- 404
        res$send(list(error = "Flight not found"))
        return()
      }
      
      # # Build update query dynamically based on provided fields
      update_fields <- names(flight_data)
      #
      # check if fields are procided
      if (length(update_fields) == 0){
        res$status <- 400
        res$json(list(error = "No fields provided for update"))
        return(TRUE)
      }
      
      set_clause <- paste(update_fields, "= ?", collapse = ", ")
      #
      query <- sprintf(
        "UPDATE flights SET %s WHERE ID = ?",
        set_clause
      )
      logger::log_info(paste("Query: ", query))
      print(query)
      #
      params <- c(as.list(flight_data), list(req$params$id))
      logger::log_info(paste("Params: ", paste(params, collapse = ", ")))
      
      dbExecute(con, query, params = params)
      
      res$send(list(
        success = TRUE,
        message = "Flight updated successfully"
      ))
    }, error = function(err) {
      logger::log_error(paste("Error: ", err$message))
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  
  #'   # 6. PUT /flights/:id - Update flight details
  #'   app$put("/flights/:id", function(req, res) {
  #'     tryCatch({
  #'       
  #'       logger::log_info("FLIGHT PUT")
  #'       #
  #'       #
  #'       # logger::log_info(paste(req$body))
  #' #'       
  #' #'       # # body existand is parse able
  #' #'       # if (is.null(req$body)){
  #' #'       #   res$status = 400
  #' #'       #   res$json(list(error = "Empty request body"))
  #' #'       #   return()
  #' #'       # }
  #' #'       # 
  #' #'       # # ensure body is character string
  #' #'       # body_text = if (is.character(req$body)){
  #' #'       #   req$body
  #' #'       # } else {
  #' #'       #   tryCatch({
  #' #'       #     as.character(req$body)
  #' #'       #   }, error = function(e){
  #' #'       #     NULL
  #' #'       #   })
  #' #'       # }
  #' #'       # 
  #' #'       # if (is.null(body_text) || nchar(body_text) == 0){
  #' #'       #   res$status = 400
  #' #'       #   res$json(list(error = "Invalid request body"))
  #' #'       #   return(TRUE)
  #' #'       # }
  #' #'       
  #' #'       # Parse JSON safely
  #' #'       flight_data <- tryCatch({
  #' #'         jsonlite::fromJSON(req$body, simplifyVector = TRUE)
  #' #'       }, error = function(e) {
  #' #'         logger::log_error(paste("JSON parse error:", e$message))
  #' #'         res$status <- 400
  #' #'         res$json(list(error = paste("Invalid JSON in request body:", e$message)))
  #' #'         return(NULL)
  #' #'       })
  #' #' 
  #' #'       if (is.null(flight_data)) return()
  #' #'       
  #' #'       # Use the helper function instead of inline parsing
  #' #'       flight_data <- parse_request_body(req)
  #' #' 
  #' #'       if (is.null(flight_data)) {
  #' #'         res$status <- 400
  #' #'         res$json(list(error = "Invalid or empty request body"))
  #' #'         return(TRUE)
  #' #'       }
  #' #' 
  #' #'       con <- get_db_connection()
  #' #'       on.exit(dbDisconnect(con), add = TRUE)
  #' #'       #
  #' #'       # Check if flight exists
  #' #'       exists <- dbGetQuery(
  #' #'         con,
  #' #'         "SELECT 1 FROM flights WHERE ID = ?",
  #' #'         params = list(req$params$id)
  #' #'       )
  #' #'       
  #' #'       print(exists)
  #' #' 
  #' #'       if (nrow(exists) == 0) {
  #' #'         res$status <- 404
  #' #'         res$json(list(error = "Flight not found"))
  #' #'         return(TRUE)
  #' #'       }
  #' #'       #
  #' #'       # # Build update query dynamically based on provided fields
  #' #'       update_fields <- names(flight_data)
  #' #' #'       #
  #' #' #'       # check if fields are procided
  #' #' #'       if (length(update_fields) == 0){
  #' #' #'         res$status <- 400
  #' #' #'         res$json(list(error = "No fields provided for update"))
  #' #' #'         return(TRUE)
  #' #' #'       }
  #' #' #'       
  #' #'       # set_clause <- paste(update_fields, "= ?", collapse = ", ")
  #' #'       # #
  #' #'       # query <- sprintf(
  #' #'       #   "UPDATE flights SET %s WHERE ID = ?",
  #' #'       #   set_clause
  #' #'       # )
  #' #'       # # print(query)
  #' #'       # #
  #' #'       # params <- c(as.list(flight_data), list(req$params$id))
  #' #' 
  #' #'       set_clauses <- vector("character", length(update_fields))
  #' #'       params <- vector("list", length(update_fields) + 1)
  #' #' 
  #' #'       for (i in seq_along(update_fields)) {
  #' #'         field <- update_fields[i]
  #' #'         set_clauses[i] <- paste0(field, " = ?")
  #' #'         params[[i]] <- flight_data[[field]]
  #' #'       }
  #' #' 
  #' #'       # Add ID as the last parameter
  #' #'       params[[length(params)]] <- req$params$id
  #' #' 
  #' #'       # Build SQL with placeholders
  #' #'       sql <- paste0(
  #' #'         "UPDATE flights SET ",
  #' #'         paste(set_clauses, collapse = ", "),
  #' #'         " WHERE ID = ?"
  #' #'       )
  #' #' 
  #' #'       # Execute update
  #' #'       logger::log_debug(paste("Executing SQL:", sql))
  #' #'       logger::log_debug(paste("With params:", paste(unlist(params), collapse=", ")))
  #' #' 
  #' #'       result <- dbExecute(con, sql, params = params)
  #'       
  #'       res$json(list(
  #'         success = TRUE,
  #'         message = "Flight updated successfully"
  #'       ))
  #'       
  #   }, error = function(err) {
  #     logger::log_error(paste("Error: ", err$message))
  #     res$status <- 500
  #     res$json(handle_error(err))
  #   })
  # })
  #
  
  # 7. DELETE /:id - Delete flight
  app$delete("/:id", function(req, res) {
    tryCatch({
      con <- get_db_connection()
      on.exit(dbDisconnect(con), add = TRUE)
      
      result <- dbExecute(
        con,
        "DELETE FROM flights WHERE ID = ?",
        params = list(req$params$id)
      )
      
      if (result == 0) {
        res$status <- 404
        res$json(list(error = "Flight not found"))
        return()
      }
      
      res$json(list(
        success = TRUE,
        message = "Flight deleted successfully"
      ))
    }, error = function(err) {
      res$status <- 500
      res$json(handle_error(err))
    })
  })
  
  return(app)
}

#===============================================================================
# Server Initialization
#===============================================================================

# Initialize application
init_app <- function() {
  
  logger::log_info("Application initialization started.")
  
  # Set start time
  Sys.setenv(R_START_TIME = as.character(Sys.time()))
  
  # Setup logging
  log_setup()
  logger::log_info("Logging setup completed.")
  
  # Process data and setup database
  logger::log_info("Initializing application")
  
  # Process data and setup database
  processed_data <- process_flights_data()
  logger::log_info("Data processing completed.")
  
  setup_database(processed_data)
  logger::log_info("Database setup completed.")
  
  # Create app with routes
  app <- create_app()
  # Start server
  logger::log_info(sprintf("Starting server on port %d", config$port))
  
  logger::log_debug(paste("Port:", config$port))
  logger::log_debug(paste("Port Type:", typeof(config$port)))
  logger::log_debug(paste("Host:", "127.0.0.1"))
  logger::log_debug(paste("Host Type:", typeof("127.0.0.1")))
  
  app$start(port = config$port, host = "127.0.0.1")
  logger::log_info("Server started.")
}

# For non-test mode, start the application
if (!interactive()) {
  init_app()
}

init_app()
