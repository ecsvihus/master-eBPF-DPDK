# Load ggplot2
library(ggplot2)
library(tidyverse)
library(data.table)
library(dplyr)
library(purrr)
library(viridis)

# Set the directory path
#path <- "./data"

# List all files
#files <- list.files(path, full.names = TRUE)

# Read all files into a named list using fread
#file_list <- files %>%
#  set_names(basename(.)) %>%   # name the list elements with file names
#  map(~ fread(.x, col.names = "latency"))             # fread each file

# Combine using bind_rows with .id
#combined_data <- bind_rows(file_list, .id = "src")

# View combined data
#head(combined_data)



path <- "./data"
files <- list.files(path, full.names = TRUE)


combined.data <- data.frame()
for (file in files) {
  filename <- strsplit(file, "/")[[1]][3]
  traffic_bandwidth <- as.numeric(strsplit(filename, "-")[[1]][2])
  type <- strsplit(filename, "-")[[1]][1]
  
  tmp <- c(fread(file, col.names = "latency") %>% mutate(file = filename, traffic = sprintf("%05d",traffic_bandwidth), fwd_type = type))
  combined.data <- rbind(combined.data,tmp)
}

combined.data <- combined.data %>% mutate(fwd_type = forcats::fct_relevel(fwd_type, c("napi", "dpdk", "xdp"))) %>% 
  mutate(fwd_type = forcats::fct_recode(fwd_type, "NAPI" = "napi", "DPDK" = "dpdk", "XDP" = "xdp"))


#all
ggplot(combined.data, aes(y = latency, color = fwd_type, x = fwd_type)) +
  #scale_color_manual(values=c("#b30000", "#ff0000", "#ff6666","#0000b3","#0000ff","#6666ff","#00b300","#00ff00","#66ff66")) +
  #stat_ecdf() +
  #stat_density() +
  stat_boxplot() +
  scale_y_log10() +
  coord_cartesian(ylim = c(44,4000))

#DPDK only
#ggplot(all.data %>% filter(src %in% c('DPDK@0G','DPDK@3G','DPDK@6G')), aes(x = latency, color = src))

#NAPI only
ggplot(combined.data %>% filter(grepl('dpdk',file)), aes(x = latency, color = factor(traffic))) +
  #scale_color_manual(values=c("#0000b3","#0000ff","#6666ff")) +
  #scale_color_discrete()
  #scale_color_gradient()
  scale_color_viridis_d(option = "cividis") +
  stat_ecdf() +
  #stat_density() +
  scale_x_log10() +
  coord_cartesian(xlim = c(44,500))


all.data %>% group_by(src) %>% summarise(meanlatency = mean(latency))

ggplot(all.data %>% filter(grepl('3G',src)), aes(x = latency, fill = src)) +
  scale_fill_manual(values=c("#b30000", "#ff0000", "#ff6666","#0000b3","#0000ff","#6666ff","#00b300","#00ff00","#66ff66")) +
  geom_histogram(position = position_dodge2()) +
  coord_cartesian(xlim = c(44, 3000)) +
  scale_x_log10()

