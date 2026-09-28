export OBJCACHE     ?= ccache

UVM_HOME            ?= $(HOME)/uvm-verilator
UVM_SRC             = $(UVM_HOME)/src
TEST_NAME           ?= base_test

ROOT                := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
TOP                 ?= top
FILES               ?= $(ROOT)/uvm_files.f
BUILD_DIR           ?= $(ROOT)/.obj_dir
BUILD_DIR_COV       ?= $(ROOT)/.obj_dir_cov
SEED                ?= $(shell date +%s)
VERILATOR_COV_DIR   ?= verilator_cov_dir

#############################################
#   Verilator (5.05x) flow
#   z3 solver is required
#############################################
VERILATOR_FLAGS :=      \
	-j 0                \
	-CFLAGS "-O0"       \
	-Wno-fatal          \
	-Wno-lint           \
	--Mdir $(BUILD_DIR) \
	--binary            \
	--build-jobs 8      \
	--quiet-stats       \
	--quiet-build       \
	--timescale 1ns/1ps \
	--timing            \
	--top-module $(TOP) \
	--trace-fst

VERILATOR_COV :=        \
	--coverage          \
	--coverage-user

UVM_FLAGS   :=                              \
	+incdir+$(UVM_SRC)                      \
	+incdir+$(CURDIR)/tb                    \
	+define+UVM_NO_DPI                      \
	+define+UVM_REPORT_DISABLE_FILE_LINE    \
	$(UVM_SRC)/uvm_pkg.sv

.PHONY: verilate run run_rand coverage functional_coverage coverage_html clean

verilate:
	@verilator $(VERILATOR_FLAGS) $(UVM_FLAGS) -f $(FILES)

verilate_cov:
	@verilator $(VERILATOR_FLAGS) $(UVM_FLAGS) $(VERILATOR_COV) -f $(FILES)

run: verilate
	@$(BUILD_DIR)/V$(TOP)                                           \
		+UVM_TESTNAME=$(TEST_NAME)                                  \
		+verilator+quiet                                            \
		+verilator+seed+$(SEED)

run_cov: verilate_cov
	@mkdir -p $(VERILATOR_COV_DIR)
	@$(BUILD_DIR)/V$(TOP)                                           \
		+verilator+quiet                                            \
		+verilator+seed+$(SEED)                                     \
		+verilator+coverage+file+$(VERILATOR_COV_DIR)/coverage.dat

coverage: run_cov
	@verilator_coverage                                             \
		--annotate $(VERILATOR_COV_DIR)/annotated                   \
		--annotate-points                                           \
		--rank                                                      \
		--write-info $(VERILATOR_COV_DIR)/coverage.info             \
		$(VERILATOR_COV_DIR)/coverage.dat

functional_coverage: run_cov
	@verilator_coverage                                             \
		--report summary                                            \
		--filter-type covergroup                                    \
		--annotate $(VERILATOR_COV_DIR)/functional_annotated        \
		--annotate-points                                           \
		$(VERILATOR_COV_DIR)/coverage.dat                           \
		> $(VERILATOR_COV_DIR)/functional_coverage.txt

coverage_html: coverage
	@genhtml $(VERILATOR_COV_DIR)/coverage.info \
		--output-directory $(VERILATOR_COV_DIR)/html

clean:
	rm -rf $(BUILD_DIR) $(VERILATOR_COV_DIR) coverage.dat


#############################################
#   RHEL / Alma / Rocky with Vivado >= 25.02
#
#   Vivado Comprehensive sim flow (coverage, etc)
#############################################
VIVADO_DIR          ?= $(ROOT)/.xsim
VIVADO_SNAPSHOT     ?= $(TOP)_xsim
VIVADO_COVERAGE_DIR ?= $(ROOT)/vivado_coverage
VIVADO_COV_DIR      ?= $(VIVADO_COVERAGE_DIR)/vivado_cov
VIVADO_REPORT       ?= $(VIVADO_COVERAGE_DIR)/vivado_report
VIVADO_TCL          := $(VIVADO_DIR)/run.tcl
VIVADO_FILELIST     := $(VIVADO_DIR)/sources.f
VIVADO_TEXT_REPORT  ?= $(VIVADO_COVERAGE_DIR)/vivado_text_report
COV_DB_NAME         ?= test_cov_db

.PHONY: vivado_compile vivado_run vivado_report vivado_clean

vivado_compile:
	@mkdir -p $(VIVADO_DIR) $(VIVADO_COV_DIR)
	@sed \
		-e '/^[[:space:]]*#/d' \
		-e '/^[[:space:]]*$$/d' \
		-e 's#^#$(ROOT)/#' \
		$(FILES) > $(VIVADO_FILELIST)
	@cd $(VIVADO_DIR) && xvlog -sv -f $(VIVADO_FILELIST)
	@cd $(VIVADO_DIR) && xelab $(TOP) \
		-s $(VIVADO_SNAPSHOT) \
		-timescale 1ns/1ps \
		-cov_db_name $(COV_DB_NAME) \
		-cov_db_dir $(VIVADO_COV_DIR)

vivado_run: vivado_compile
	@mkdir -p $(VIVADO_DIR) $(VIVADO_COV_DIR) $(VIVADO_REPORT)
	@{                                                                                                                      \
		echo "run -all";                                                                                                    \
		echo "write_xsim_coverage -cov_db_name $(COV_DB_NAME) -cov_db_dir $(VIVADO_COV_DIR)";                               \
		echo "export_xsim_coverage -cov_db_name $(COV_DB_NAME) -cov_db_dir $(VIVADO_COV_DIR) -output_dir $(VIVADO_REPORT)"; \
		echo "exit";                                                                                                        \
	} > $(VIVADO_TCL)
	@cd $(VIVADO_DIR) && xsim $(VIVADO_SNAPSHOT) \
		-sv_seed $(SEED) \
		-tclbatch $(VIVADO_TCL)

vivado_report: vivado_run
	@mkdir -p $(VIVADO_TEXT_REPORT)
	@xcrg -dir $(VIVADO_COV_DIR)/xsim.covdb -report_format text -report_dir $(VIVADO_TEXT_REPORT) -log /dev/null
	@echo "Reports written to:"
	@echo "  HTML: $(VIVADO_REPORT)"
	@echo "  Text: $(VIVADO_TEXT_REPORT)"

vivado_clean:
	@rm -rf $(VIVADO_DIR) $(VIVADO_COV_DIR) $(VIVADO_REPORT) $(VIVADO_TEXT_REPORT) $(VIVADO_COVERAGE_DIR) xsim.covdb

#############################################
#   Vivado lean simulation flow
#############################################
VIVADO_SIM_DIR       ?= $(ROOT)/.xsim_sim
VIVADO_SIM_SNAPSHOT  ?= $(TOP)_sim
VIVADO_SIM_TCL       := $(VIVADO_SIM_DIR)/run.tcl
VIVADO_SIM_FILELIST  := $(VIVADO_SIM_DIR)/sources.f

.PHONY: vivado_sim_compile vivado_sim_run vivado_sim_clean

vivado_sim_compile:
	@mkdir -p $(VIVADO_SIM_DIR)
	@sed                                                                                                                \
		-e '/^[[:space:]]*#/d'                                                                                          \
		-e '/^[[:space:]]*$$/d'                                                                                         \
		-e 's#^#$(ROOT)/#'                                                                                              \
		$(FILES) > $(VIVADO_SIM_FILELIST)
	@cd $(VIVADO_SIM_DIR) && {                                                                                          \
		xvlog -sv -nolog -f $(VIVADO_SIM_FILELIST) > .xvlog.out 2>&1 || { cat .xvlog.out; rm -f .xvlog.out; exit 1; };  \
		rm -f .xvlog.out;                                                                                               \
	}
	@cd $(VIVADO_SIM_DIR) && {                                                                                          \
		xelab -nolog $(TOP) -s $(VIVADO_SIM_SNAPSHOT) -timescale 1ns/1ps > .xelab.out 2>&1 || { cat .xelab.out; rm -f .xelab.out; exit 1; }; \
		rm -f .xelab.out;                                                                                               \
	}

vivado_sim_run: vivado_sim_compile
	@{                                                                                                                  \
		echo "run -all";                                                                                                \
		echo "exit";                                                                                                    \
	} > $(VIVADO_SIM_TCL)
	@cd $(VIVADO_SIM_DIR) && {                                                                                          \
		xsim $(VIVADO_SIM_SNAPSHOT) -nolog -sv_seed $(SEED) -tclbatch $(VIVADO_SIM_TCL) > .xsim.out 2>&1 || { cat .xsim.out; rm -f .xsim.out; exit 1; }; \
		sed -E                                                                                                          \
			-e '/^(INFO: \[|Vivado Simulator|Copyright|Running:|Multi-threading|Starting |Pass Through|Completed |Time Resolution|Compiling |Built simulation snapshot|source |# xsim|## (run|exit)|INFO: xsimkernel|INFO: \[Common)/d' \
			-e '/^[[:space:]]*\*{4}/d'                                                                                  \
			.xsim.out;                                                                                                  \
		rm -f .xsim.out;                                                                                                \
	}

vivado_sim_clean:
	@rm -rf $(VIVADO_SIM_DIR)
