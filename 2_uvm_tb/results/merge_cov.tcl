merge -out merged_cov -overwrite cov_work/scope/run_smoke cov_work/scope/run_reg cov_work/scope/run_ram cov_work/scope/run_fifo cov_work/scope/run_error cov_work/scope/run_timer cov_work/scope/run_random
load -run cov_work/scope/merged_cov
report -summary -out combined_coverage.txt
