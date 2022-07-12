### STEP BY STEP USING R TO ESTIMATE POOLED SENSITIVITY AND SPECIFICITY OF DIAGNOSTIC TOOLS ### Modified by Naiyana ###

#1) Load package "meta"
library(meta)

#2) Open an example data of 2 by 2 table from "lung.txt"

ccdata <- read.table("RDT_2.txt", header=TRUE, as.is=TRUE)
attach(ccdata)


#3) Estimate sensitivity and specificity of individual and overall study

sens <- tp/(tp+fn)
sens.overall <- sum(tp)/sum(tp+fn)
spec <- tn/(tn+fp)
spec.overall <- sum(tn)/sum(tn+fp)


#4) Create histogram "SROC figure"

par(mar=c(5.1,4.1,0.1,0.1))					#Specify size of figure
plot(1-spec,sens,xlim=0:1,ylim=0:1)				#Plot histogram
points(1-spec.overall,sens.overall,pch="+",cex=2)		#Add marker into the histogram

#4.1) SPECIFY THE SIZE OF FIGURE
	# the "mar" specify the margins of the figure in number of lines
	# the "mai" specify the margins of the figure in number of inches
	# the "oma" stands for "Outer margin area", or the total margin space that is outside of the standard plotting region (see graph)
	# the vector is ordered, the first value corresponding to the bottom, the entire array is c(bottom, left, top, right)
	# By default the size is c(5,4,4,2) + 0.1, (equivalent to c(5.1,4.1,4.1,2.1)).   
	# By default the axes tick marks will go in the first line of the left and bottom with the axis label going in the second line.  
	# By default the title will fit in the third line on the top of the graph. 

#4.2) Plot => plot(x, y, type="n", xlim=NULL, ylim=NULL, xlab="X", ylab="Y")    
	# "x" stands for name of parameter to be plotted in x-axis
	# "y" stands for name of parameter to be plotted in y-axis
	# "xlab" stands for x-axis label
	# "ylab" stands for y-axis label
	# type="n" hides the points


#5) Calculate summary statistics i.e. treatment effects, SE of treatment effects

	te1 <- sens
	se1 <- sqrt(sens.overall*(1-sens.overall)/(tp+fn))
	sens.ma <- metagen(TE=te1, seTE=se1, studlab=Study, sm="Sensitivity")

	te2 <- spec
	se2 <- sqrt(spec.overall*(1-spec.overall)/(tn+fp))
	spec.ma <- metagen(TE=te2, seTE=se2, studlab=Study, sm="Specificity")

#5.1) Report summary table of statistics

	sens.ma
	spec.ma


#6) List individual parameter including of 
	#[1] sensitity of each study 
	#[2] se of each study 
	#[3] pooled sensitivity from fixed effect model
	#[4] se of [3]
	#[5] pooled sensitivity from random effect model
	#[6] se of [5]


#6.1) Create forest plot

	list (sens.ma$TE, sens.ma$seTE, sens.ma$TE.fixed, sens.ma$seTE.fixed, sens.ma$lower.fixed, sens.ma$upper.fixed, sens.ma$TE.random, sens.ma$seTE.random, sens.ma$lower.random, sens.ma$upper.random)
	forest (sens.ma,studlab=Study)

	list (spec.ma$TE, spec.ma$seTE, spec.ma$TE.fixed, spec.ma$seTE.fixed, spec.ma$lower.fixed, sens.ma$upper.fixed, spec.ma$TE.random, spec.ma$seTE.random, spec.ma$lower.random, spec.ma$upper.random)
	forest (spec.ma,studlab=Study)


#7) Create funnel plot to assess asymmetry
### funnel(x, y, xlim=NULL, ylim=NULL, xlab=NULL, ylab=NULL,
#       comb.f=FALSE, axes=TRUE,
#       pch=1, text=NULL, cex=1, col=NULL,
#       log="", yaxis="se", sm=NULL,
#       level=NULL, ...)
### radial(x, y, xlim=NULL, ylim=NULL,
#       xlab="Inverse of standard error",
#       ylab="Standardised treatment effect (z-score)",
#       comb.f=TRUE, axes=TRUE,
#       pch=1, text=NULL, cex=1, col=NULL,
#       level=NULL, ...)
### Arguments
#x	 An object of class meta, or estimated treatment effect in individual studies.
#y	 Standard error of estimated treatment effect (mandatory if x not of class meta).
#xlim	 The x limits (min,max) of the plot.
#ylim	 The y limits (min,max) of the plot.
#xlab	 A label for the x axis.
#ylab	 A label for the y axis.
#comb.f	 A logical indicating whether the pooled fixed effects estimate should be plotted.
#axes	 A logical indicating whether axes should be drawn on the plot.
#pch	 The plotting symbol used for individual studies.
#text	 A character vector specifying the text to be used instead of plotting symbol.
#cex	 The magnification to be used for plotting symbol.
#col	 A vector with color of plotting symbols.
#log	 A character string which contains "x" if the x axis is to be logarithmic, "y" if the y axis is to be logarithmic and "xy" or "yx" if both axes are to be logarithmic (applies only to function funnel).
#yaxis	 A character string indicating which type of weights are to be used. Either "se", "invvar", "invse", or "size" (applies only to function funnel).
#sm	 A character string indicating underlying summary measure, e.g., "RD", "RR", "OR", "WMD", "SMD" (applies only to function funnel).
#level	 The confidence level utilised in the plot.
#...	 Graphical parameters as in par may also be passed as arguments.


funnel(te1,se1)			#Simple plot
funnel(te1,se1,xlab="Sensitivity",ylab="Standard error")	#Format axis-label
funnel(te1,se1,xlim=0:1,ylim=0:1,xlab="Sensitivity",ylab="Standard error")	#Specify min-max of x- and y-axis
funnel(sens.ma, random = TRUE)									#Assess funnel plot asymmetry
funnel(sens.ma$TE, sens.ma$seTE, random = TRUE, level=0.95)			#Assess funnel plot asymmetry under 95% CI level
funnel(spec.ma)
funnel(spec.ma$TE, spec.ma$seTE, comb.f=TRUE, level=0.95)

sens.ma.frame <- data.frame(RDT = c("Sensitivity"), Overall = c(sens.ma$TE.random), se = c(sens.ma$seTE.random), lowerCI = c(sens.ma$lower.random), upperCI = c(sens.ma$upper.random), stringsAsFactors = FALSE)

spec.ma.frame <- data.frame(RDT = c("Specificity"), Overall = c(spec.ma$TE.random), se = c(spec.ma$seTE.random), lowerCI = c(spec.ma$lower.random), upperCI = c(spec.ma$upper.random), stringsAsFactors = FALSE)