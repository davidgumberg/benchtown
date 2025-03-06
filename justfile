# Main deploy command
deploy: checkout-benchcoin move-benchcoin setup-dependencies build

# Check out results from bitcoin-dev-tools/benchcoin repo
checkout-benchcoin:
    @echo "Checking out benchcoin repository..."
    git clone --depth 1 --branch gh-pages https://github.com/bitcoin-dev-tools/benchcoin temp_benchcoin

# Move results to the right location
move-benchcoin:
    @echo "Moving benchcoin results..."
    mkdir -p src/benchcoin
    mv temp_benchcoin/results/* src/benchcoin/ || exit 1
    rm -rf temp_benchcoin

# Setup Ruby and Node dependencies
setup-dependencies:
    @echo "Setting up dependencies..."
    # Ruby setup
    bundle install
    # Node setup
    yarn install

# Build the project
build:
    @echo "Deploy project..."
    bin/bridgetown deploy

# Clean up temporary files and build artifacts
clean:
    rm -rf temp_benchcoin
