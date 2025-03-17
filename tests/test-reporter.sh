#!/usr/bin/env bash

# Set the test results directory with a default that works locally and in CI
TEST_RESULTS_DIR="${GITHUB_WORKSPACE:-.}/test-results"

get_current_test_class() {
    # Find the most recent class file
    for class_file in "$TEST_RESULTS_DIR/"*-class.txt; do
        if [ -f "$class_file" ]; then
            basename "$class_file" | sed 's/-class.txt//'
            return 0
        fi
    done
    
    # If no class file found, return error
    echo "ERROR: Could not determine test class. Make sure initialize_test was called first." >&2
    return 1
}

initialize_test() {
    local test_name="$1"
    local test_class="$2"
    
    # Create directory for test results
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Store test metadata in files to ensure persistence across steps
    echo "$test_name" > "$TEST_RESULTS_DIR/${test_class}-name.txt"
    echo "$test_class" > "$TEST_RESULTS_DIR/${test_class}-class.txt"
    
    # Clear any existing test cases file
    echo "" > "$TEST_RESULTS_DIR/${test_class}-cases.txt"
    
    echo "📋 Running test: $test_name"
}

# Internal assert function
assert() {
    local name="$1"
    local result="$2"  # true or false
    local message="$3"
    
    local test_class=$(get_current_test_class)
    if [ $? -ne 0 ]; then
        return 1  # Error already reported by get_current_test_class
    fi
    
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
    local test_class=$(get_current_test_class)
    if [ $? -ne 0 ]; then
        return 1  # Error already reported by get_current_test_class
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
            echo "        <testcase name=\"$name\" classname=\"$test_class\" time=\"0\">
            <system-out>$message</system-out>
        </testcase>" >> "$TEST_RESULTS_DIR/$test_class.xml"
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
