icmp <- read.csv("./combined.csv")

x <- 1:1000

print(seq_along(cars))

par( mfrow= c(2,2))

matplot(x, cbind(icmp$flood,icmp$floodDPDK,icmp$floodeBPF), type = "l", lty = 1,
        col = c("red", "blue", "green"), xlab = "X",
        ylab = "ms", main = "flood")

legend("topright", legend = c("Linux", "DPDK", "eBPF"),
       col = c("red", "blue", "green"),
       lty = 1)


matplot(x, cbind(icmp$bigflood,icmp$bigfloodDPDK,icmp$bigfloodeBPF), type = "l", lty = 1,
        col = c("red", "blue", "green"), xlab = "X",
        ylab = "ms", main = "big flood")

legend("topright", legend = c("Linux", "DPDK", "eBPF"),
       col = c("red", "blue", "green"),
       lty = 1)


matplot(x, cbind(icmp$ping,icmp$pingDPDK,icmp$pingeBPF), type = "l", lty = 1,
        col = c("red", "blue", "green"), xlab = "X",
        ylab = "ms", main = "ping")

legend("topright", legend = c("Linux", "DPDK", "eBPF"),
       col = c("red", "blue", "green"),
       lty = 1)