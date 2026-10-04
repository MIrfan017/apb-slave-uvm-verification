# Makefile
TEST 		= apb_wr_rd_test
#apb_base_test
TIME_OUT	= 9200000

compile:
	vcs -sverilog -f build.flist -ntb_opts uvm-1.2 +UVM_TESTNAME=$(TEST) -cm line+cond+tgl+assert -LDFLAGS -Wl,--no-as-needed -full64 -debug_all +UVM_TIMEOUT=$(TIME_OUT)
	cd ./out && rm -rf build_$(TEST)
	cd ./out && mkdir build_$(TEST)
	mv csrc simv.daidir simv.vdb simv vc_hdrs.h ./out/build_$(TEST)

# for simulation
sim: 
	cd ./out/build_$(TEST) && ./simv -cm line+cond+tgl+assert +UVM_TESTNAME=$(TEST)  +UVM_TIMEOUT=$(TIME_OUT) > log_build_$(TEST).log

# To view waveform, run `make gui` command in the terminal
gui: 
	cd ./out/build_$(TEST) && dve -vpd waveform.vpd	

# More advance make targets
cov:
	urg -report  ./out/coverage_report -dir  ./out/build_*/*.vdb


clean: 
	rm -rf ./out/build_$(TEST)

allclean:
	rm -rf ./out/*


dve_cov:
	dve -covdir simv.vdb



# ---------------------------------------------------------------------------
# Run a single test (compile + sim) :  make run TEST=apb_err_test
# ---------------------------------------------------------------------------
run: compile sim

# ---------------------------------------------------------------------------
# Separate target for each test
# ---------------------------------------------------------------------------
wr_rd:
	$(MAKE) run TEST=apb_wr_rd_test

random:
	$(MAKE) run TEST=apb_random_test

err:
	$(MAKE) run TEST=apb_err_test

alias:
	$(MAKE) run TEST=apb_err_alias_test

b2b:
	$(MAKE) run TEST=apb_b2b_test

# ---------------------------------------------------------------------------
# Run all tests, then merge coverage of all of them
# ---------------------------------------------------------------------------
TESTS = apb_wr_rd_test apb_random_test apb_err_test apb_err_alias_test apb_b2b_test

all_tests:
	for t in $(TESTS); do $(MAKE) run TEST=$$t || exit 1; done
	$(MAKE) cov

.PHONY: run wr_rd random err alias b2b all_tests