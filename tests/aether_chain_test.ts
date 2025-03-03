// [Previous test imports and setup remain unchanged...]

Clarinet.test({
    name: "Product status management test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        
        // Register manufacturer and product
        let block1 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address),
            Tx.contractCall('aether-chain', 'register-product-batch', [
                types.list([types.ascii("PROD001")]),
                types.ascii("Luxury Watch"),
                types.uint(52560),
                types.uint(17280)
            ], manufacturer.address)
        ]);
        
        // Update product status
        let block2 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'update-product-status', [
                types.ascii("PROD001"),
                types.ascii("SERVICING")
            ], manufacturer.address)
        ]);
        
        block1.receipts[0].result.expectOk();
        block1.receipts[1].result.expectOk();
        block2.receipts[0].result.expectOk();
        
        // Verify status update
        let block3 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'get-product-info', [
                types.ascii("PROD001")
            ], deployer.address)
        ]);
        
        const productInfo = block3.receipts[0].result.expectSome().expectTuple();
        assertEquals(productInfo['status'], types.ascii("SERVICING"));
    }
});

// [Remaining tests unchanged...]
