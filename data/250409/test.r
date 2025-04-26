# Load ggplot2
library(ggplot2)
library(tidyverse)
library(data.table)

all.data <-
  bind_rows(
    "DPDK@0G" = fread("dpdk-0G.dat", col.names = "latency"),
    "DPDK@3G" = fread("dpdk-3G.dat", col.names = "latency"),
    "DPDK@6G" = fread("dpdk-6G.dat", col.names = "latency"),
    "NAPI@0G" = fread("napi-0G.dat", col.names = "latency"),
    "NAPI@3G" = fread("napi-3G.dat", col.names = "latency"),
    "NAPI@6G" = fread("napi-6G.dat", col.names = "latency"),
    "XDP@0G" = fread("xdp-0G.dat", col.names = "latency"),
    "XDP@3G" = fread("xdp-3G.dat", col.names = "latency"),
    "XDP@6G" = fread("xdp-6G.dat", col.names = "latency"),
    .id = "src"
  ) %>% mutate(latency = 1000 * latency)

#all
ggplot(all.data, aes(x = latency, color = src)) +
  scale_color_manual(values=c("#b30000", "#ff0000", "#ff6666","#0000b3","#0000ff","#6666ff","#00b300","#00ff00","#66ff66")) +
  stat_ecdf() +
  #stat_density() +
  #stat_boxplot() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#DPDK only
ggplot(all.data %>% filter(src %in% c('DPDK@0G','DPDK@3G','DPDK@6G')), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#b30000", "#ff0000", "#ff6666")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#NAPI only
ggplot(all.data %>% filter(grepl('NAPI',src)), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#0000b3","#0000ff","#6666ff")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#XDP only
ggplot(all.data %>% filter(grepl('XDP',src)), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#00b300","#00ff00","#66ff66")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#0G only
ggplot(all.data %>% filter(grepl('0G',src)), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#b30000","#0000b3","#00b300")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#3G only
ggplot(all.data %>% filter(grepl('3G',src)), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#ff0000","#0000ff","#00ff00")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))

#6G only
ggplot(all.data %>% filter(grepl('6G',src)), aes(x = latency, color = src)) +
  scale_color_manual(values=c("#ff6666","#6666ff","#66ff66")) +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,3000))




all.data %>% group_by(src) %>% summarise(meanlatency = mean(latency))

ggplot(all.data %>% filter(grepl('3G',src)), aes(x = latency, fill = src)) +
  scale_fill_manual(values=c("#b30000", "#ff0000", "#ff6666","#0000b3","#0000ff","#6666ff","#00b300","#00ff00","#66ff66")) +
  geom_histogram(position = position_dodge2()) +
  coord_cartesian(xlim = c(44, 3000)) +
  scale_x_log10()

