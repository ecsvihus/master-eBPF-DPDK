# Load ggplot2
library(ggplot2)
library(gridExtra)
#library(ggpubr)

histogramDF <- data.frame(
  type=c('xdp','dpdk','linux'),
  latency=c(scan("./ping-xdp.dat")*1000,scan("./ping-dpdk.dat")*1000,scan("./ping-linux.dat")*1000)
)


iperf_xdp <- data.frame(
#  latency=c('latency'),
  latency = scan("./ping-xdp.dat")*1000
)

iperf_dpdk <- data.frame(
#  latency=c('latency'),
  latency = scan("./ping-dpdk.dat")*1000
)

iperf_linux <- data.frame(
#  latency=c('latency'),
  latency = scan("./ping-linux.dat")*1000
)


# Create data
m256xdp <- data.frame(
  latency=c("10","20","30","40","50","60","70","80","90","100","200","300","400","500","600","700","800","900","1000"),
  #value=c(40969,202817,231785,94548,23821,2767,488,290,85,506,1430,275,174,147,63,69,76,69,74)
  value=c(54019,211761,227514,80702,20707,2396,452,236,137,415,1278,180,177,144,58,66,74,59,78)
)

m256dpdk <- data.frame(
  latency=c("10","20","30","40","50","60","70","80","90","100","200","300","400","500","600","700","800","900","1000"),
  value=c(586246,12632,39,26,24,27,22,22,24,496,451,129,109,58,33,27,29,24,34)
)

m256linux <- data.frame(
  latency=c("10","20","30","40","50","60","70","80","90","100","200","300","400","500","600","700","800","900","1000"),
  value=c(79,489352,84730,17085,3932,1531,418,174,112,1000,1203,160,223,102,96,75,66,51,65)
)





m256xdp$latency <- factor(m256xdp$latency, levels=m256xdp$latency)
m256dpdk$latency <- factor(m256dpdk$latency, levels=m256dpdk$latency)
m256linux$latency <- factor(m256linux$latency, levels=m256linux$latency)

#ggplot(histogramDF, aes(x=latency, color=type)) + geom_histogram(binwidth = 1/10, position="dodge") +
        #scale_x_continuous(breaks=seq(0,1500,10)) + 
#        scale_y_continuous(breaks=seq(0,40000,5000)) +
#        scale_x_log10(breaks=seq(0,1500,100))

iperfXDP <- ggplot(iperf_xdp, aes(x=latency)) + geom_histogram(binwidth = 1/10) + 
	#scale_x_continuous(breaks=seq(0,1500,10)) + 
	#scale_y_continuous(breaks=seq(0,40000,5000)) +
	coord_cartesian(xlim=c(0,2000)) +
#	scale_x_log10(breaks=seq(0,1500,100)) + 
	scale_x_log10()

iperfDPDK <- ggplot(iperf_dpdk, aes(x=latency)) + geom_histogram(binwidth = 1/10) +
	#scale_y_continuous(breaks=seq(0,40000,5000)) +
	#coord_cartesian(xlim=c(0,40000)) +
	scale_x_log10()

iperfLinux <- ggplot(iperf_linux, aes(x=latency)) + geom_histogram(binwidth = 1/10) +
        #scale_y_continuous(breaks=seq(0,40000,5000)) +
	#coord_cartesian(xlim=c(0,40000)) +
	scale_x_log10()




# Barplot
xdp <- ggplot(m256xdp, aes(x=latency, y=value)) + 
  geom_bar(stat = "identity") +
  ggtitle("XDP@M256")


# Barplot
dpdk <- ggplot(m256dpdk, aes(x=latency, y=value)) +
  geom_bar(stat = "identity") + 
  ggtitle("DPDK@M256")


linux <- ggplot(m256linux, aes(x=latency, y=value)) +
  geom_bar(stat = "identity") +
  ggtitle("Linux@M256")


grid.arrange(iperfXDP, iperfDPDK, iperfLinux, nrow = )

