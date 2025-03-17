#!/usr/bin/env bash

# Set the test results directory with a default that works locally and in CI
TEST_RESULTS_DIR="${GITHUB_WORKSPACE:-.}/test-results"

initialize_test() {
    local test_name="$1"
    local test_class="$2"
    
    # Create directory for test results
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Store test metadata in files to ensure persistence across steps
    echo "$test_name" > "$TEST_RESULTS_DIR/${test_class}-name.txt"
    echo "$test_class" > "$TEST_RESULTS_DIR/${test_class}-class.txt"

    # Export value for future method calls
    export TEST_CLASS="$test_class"
    
    # Clear any existing test cases file
    echo "" > "$TEST_RESULTS_DIR/${test_class}-cases.txt"
    
    echo "📋 Running test: $test_name"
}

# Internal assert function
assert() {
    local name="$1"
    local result="$2"  # true or false
    local message="$3"
    local test_class=$(cat "$TEST_RESULTS_DIR/${TEST_CLASS}-class.txt" 2>/dev/null || echo "$TEST_CLASS")
    
    # Escape XML special characters
    message=$(echo "$message" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
    name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
    
    # Append to the test cases file with status (S=success, F=failure)
    if [ "$result" = true ]; then
        echo "S|$name|$message" >> "$TEST_RESULTS_DIR/${test_class}-cases.txt"
        echo "✅ $name: $message"
    else
        echo "F|$name|$message" >> "$TEST_RESULTS_DIR/${test_class}-cases.txt"
        echo "❌ $name: $message"
    fi
}

success() {
    local name="$1"
    local message="$2"
    assert "$name" true "$message"
}

failure() {
    local name="$1"
    local message="$2"
    assert "$name" false "$message"
}

# Finalize the test suite
finalize_test() {
    local test_class="${TEST_CLASS}"
    
    # If TEST_CLASS isn't set, try to read from file
    if [ -z "$test_class" ]; then
        for class_file in "$TEST_RESULTS_DIR/"*-class.txt; do
            if [ -f "$class_file" ]; then
                test_class=$(cat "$class_file")
                break
            fi
        done
    fi
    
    local test_name=$(cat "$TEST_RESULTS_DIR/${test_class}-name.txt")
    local cases_file="$TEST_RESULTS_DIR/${test_class}-cases.txt"
    
    # Count total and failed tests
    local total=$(grep -v "^$" "$cases_file" | wc -l)
    local failures=$(grep "^F|" "$cases_file" | wc -l)
    
    # Start building the XML
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testsuites>
    <testsuite name=\"$test_class\" tests=\"$total\" failures=\"$failures\" errors=\"0\" skipped=\"0\" timestamp=\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\">" > "$TEST_RESULTS_DIR/$test_class.xml"
    
    # Process each test case
    while IFS="|" read -r status name message || [ -n "$status" ]; do
        if [ -z "$status" ]; then
            continue
        fi
        
        if [ "$status" = "S" ]; then
            echo "        <testcase name=\"$name\" classname=\"$test_class\" time=\"0\"/>" >> "$TEST_RESULTS_DIR/$test_class.xml"
        else  # status = F
            echo "        <testcase name=\"$name\" classname=\"$test_class\" time=\"0\">
            <failure message=\"$message\"></failure>
        </testcase>" >> "$TEST_RESULTS_DIR/$test_class.xml"
        fi
    done < "$cases_file"
    
    # Close the XML
    echo "    </testsuite>
</testsuites>" >> "$TEST_RESULTS_DIR/$test_class.xml"
    
    # Clean up temporary files
    rm -f "$TEST_RESULTS_DIR/${test_class}-name.txt"
    rm -f "$TEST_RESULTS_DIR/${test_class}-class.txt"
    rm -f "$TEST_RESULTS_DIR/${test_class}-cases.txt"
    
    echo "✨ Test complete: $test_name"
    echo "Results: $((total-failures))/$total passed"

    cat "$TEST_RESULTS_DIR/$test_class.xml"
    
    # Return appropriate exit code
    if [ "$failures" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# If this script is being run directly (not sourced), display usage info
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Test Helpers Script"
    echo "This script is designed to be sourced from test scripts, not run directly."
    echo ""
    echo "Usage within a test script:"
    echo "  source $(basename "${BASH_SOURCE[0]}")"
    echo "  init_test \"Test Name\" \"test-class\""
    echo "  # Run tests, using success() and failure() functions"
    echo "  success \"Test Case\" \"Test passed message\""
    echo "  failure \"Test Case\" \"Test failed message\""
    echo "  finalize_test"
    echo ""
    echo "Results will be written to JUnit XML format at: $TEST_RESULTS_DIR"
    exit 1
fi
