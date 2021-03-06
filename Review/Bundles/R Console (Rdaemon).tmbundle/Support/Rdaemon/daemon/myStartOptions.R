#################################################################################################
# start script for TextMate's Rdaemon
#
#   this file is loaded via "sys.source(...,  envir = attach(NULL, name = "Rdaemon"))"
#
#
#
####### please change the following lines only if you know what do you are doing


#########################################################################################
####################################### internals #######################################
#########################################################################################
if (getRversion() < "2.7") {
quartz <- function(display = "", width = 9, height = 9, pointsize = 12, 
	family = "Helvetica", antialias = TRUE, autorefresh = TRUE) {
	library(CarbonEL)
	.External("Quartz", display, width, height, pointsize, 
		family, antialias, autorefresh, PACKAGE = "grDevices")
	invisible()
}
}

file.edit <- function(..., title = file, editor = "mate") {
	file <- c(...)
	.Internal(file.edit(file, rep(as.character(title), len = length(file)), 
		editor))
}

file.choose <- function() {
	system("osascript -e 'tell application \"TextMate\"' -e 'activate' -e 'POSIX path of (choose file)' -e 'end tell' 2>/dev/null", intern=T)
}

menu <- function(choises, graphics=FALSE,  title="Rdaemon") {
	res=system(paste("~/Rdaemon/daemon/menu.sh", " '", paste('"', choises, '"', sep='', collapse=','), "' '", title, "'",  sep=''), intern=T)
	return(ifelse(length(which(choises==res))>0, which(choises==res),  0))
}

select.list <- function(list, preselect = NULL, multiple = FALSE, title="Rdaemon") {
	if(multiple) {
		multipleArg <- "with multiple selections allowed"
	} else {
		multipleArg <- ""
		if(!is.null(preselect)) preselect <- preselect[1]
	}
	res=system(paste("~/Rdaemon/daemon/selectlist.sh", " '", paste('"', list, '"', sep='', collapse=','), "' '", title, "' '", paste('"', preselect, '"', sep='', collapse=','), "' '", multipleArg, "'", sep=''), intern=T)
	res <- unlist(strsplit(res, "!@#@!"))[-1]
	if(!length(res)) return(character(0))
	return(res)
}

readline <- function(prompt = "",  alert=FALSE) {
	input <- "default answer \"\""
	if(alert) input <- ""
	res=system(paste("~/Rdaemon/daemon/readline.sh", " '", prompt, "' '", input , "'", sep=''), intern=T)
	return(res)
}

demo <- function (topic, package = NULL, lib.loc = NULL, character.only = FALSE, 
    verbose = getOption("verbose")) 
{
    paths <- .find.package(package, lib.loc, verbose = verbose)
    paths <- paths[file_test("-d", file.path(paths, "demo"))]
    if (missing(topic)) {
        db <- matrix(character(0), nrow = 0, ncol = 4)
        for (path in paths) {
            entries <- NULL
            if (file_test("-f", INDEX <- file.path(path, "Meta", 
                "demo.rds"))) {
                entries <- .readRDS(INDEX)
            }
            if (NROW(entries) > 0) {
                db <- rbind(db, cbind(basename(path), dirname(path), 
                  entries))
            }
        }
        colnames(db) <- c("Package", "LibPath", "Item", "Title")
        footer <- if (missing(package)) 
            paste("Use ", sQuote(paste("demo(package =", ".packages(all.available = TRUE))")), 
                "\n", "to list the demos in all *available* packages.", 
                sep = "")
        else NULL
        y <- list(title = "Demos", header = NULL, results = db, 
            footer = footer)
        class(y) <- "packageIQR"
        return(y)
    }
    if (!character.only) 
        topic <- as.character(substitute(topic))
    available <- character(0)
    paths <- file.path(paths, "demo")
    for (p in paths) {
        files <- basename(tools::list_files_with_type(p, "demo"))
        files <- files[topic == tools::file_path_sans_ext(files)]
        if (length(files) > 0) 
            available <- c(available, file.path(p, files))
    }
    if (length(available) == 0) 
        stop(gettextf("No demo found for topic '%s'", topic), 
            domain = NA)
    if (length(available) > 1) {
        available <- available[1]
        warning(gettextf("Demo for topic '%s' found more than once,\nusing the one found in '%s'", 
            topic, dirname(available[1])), domain = NA)
    }
    cat("\n\n", "\tdemo(", topic, ")\n", "\t---- ", rep.int("~", 
        nchar(topic, type = "w")), "\n", sep = "")
    if (interactive()) {
        #cat("\nType  <Return>\t to start : ")
        readline("Press RETURN to start the demo.", alert=TRUE)
    }
    source(available, echo = TRUE, max.deparse.length = 250)
}

alarm <- function() {
	system("osascript -e beep")
}

.chooseActiveScreenDevice <- function() {
	plots <- dev.list()
	out <- ""
	if (getRversion() < "2.7") {
		exclDevs <- c("pdf", "postscript")
	} else {
		exclDevs <- c("pdf", "postscript", "quartz_off_screen")
	}
	if (length(plots) > 0) {
		actPlot <- dev.cur()
		randomNum <- rnorm(1, mean = 10) * 1e+05
		plotPathPref <- paste("file://", Sys.getenv("HOME"), 
			"/Rdaemon/plots/tmp/Rplot_", randomNum, "_", 
			sep = "", collapse = "")
		for (i in 1:(length(plots))) {
			borderCol <- ifelse(actPlot == plots[i], "red", 
			  "#DDDDDD")
			btnVisibility <- ifelse(actPlot == plots[i], 
			  "hidden", "visible")
			if (!names(plots[i]) %in% exclDevs) {
			  dev.set(plots[i])
			  out <- paste(out, "<div id='dev", plots[i], 
				"'><h3>Device ", plots[i], " (", names(plots[i]), 
				")</h3>", sep = "", collapse = "")
			  out <- paste(out, "<img onclick='setAct(this.id)' id=", 
				plots[i], "_", (i - 1), " style='border:3px solid ", 
				borderCol, "' width=90% src='", plotPathPref, 
				sprintf("%03d", plots[i]), ".pdf", "'/><br>", 
				sep = "", collapse = "")
			  dev.print(pdf, file = paste("~/Rdaemon/plots/tmp/Rplot_", 
				randomNum, "_", sprintf("%03d", plots[i]), 
				".pdf", sep = "", collapse = ""))
			  out <- paste(out, "<button style='visibility:", 
				btnVisibility, "' id=", plots[i], "_", (i - 
				  1), " onclick='closeMe(this.id)'>Close Device</button>", 
				sep = "", collapse = "")
			  out <- paste(out, "<input type='button' id=", 
				plots[i], "_", (i - 1), " onclick='saveMe(this.id)' value='Save'>", 
				sep = "", collapse = "")
			  out <- paste(out, "</div>", sep = "", collapse = "")
			}
			else {
			  out <- paste(out, "<div id='dev", plots[i], 
				"'><h3>Device ", plots[i], " (", names(plots[i]), 
				")</h3>", "<font color=red>is not a screen device</font>", 
				sep = "", collapse = "")
			  out <- paste(out, "<img onclick='setAct(this.id)' id=", 
				plots[i], "_", (i - 1), " style='border:3px solid ", 
				borderCol, "' width=90% src='file://", Sys.getenv("HOME"), 
				"/Rdaemon/daemon/dummy_noimage.pdf'/><br>", 
				sep = "", collapse = "")
			  out <- paste(out, "<button style='visibility:", 
				btnVisibility, "' id=", plots[i], "_", (i - 
				  1), " onclick='closeMe(this.id)'>Close Device</button>", 
				sep = "", collapse = "")
			  out <- paste(out, "</div>", sep = "", collapse = "")
			}
		}
		dev.set(actPlot)
	}
	out
}
