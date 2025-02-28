// [Previous test imports and setup remain unchanged...]

Clarinet.test({
    name: "Batch product registration test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        
        // Register manufacturer
        let block1 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address)
        ]);
        
        // Register batch of products
        let block2 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-product-batch', [
                types.list([
                    types.ascii("PROD001"),
                    types.ascii("PROD002"),
                    types.ascii("PROD003")
                ]),
                types.ascii("Luxury Watch Collection 2024"),
                types.uint(52560),
                types.uint(17280)
            ], manufacturer.address)
        ]);
        
        block1.receipts[0].result.expectOk();
        block2.receipts[0].result.expectOk();
        
        // Verify products
        let block3 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'get-product-info', [
                types.ascii("PROD001")
            ], deployer.address),
            Tx.contractCall('aether-chain', 'get-product-info', [
                types.ascii("PROD002")
            ], deployer.address)
        ]);
        
        block3.receipts[0].result.expectSome();
        block3.receipts[1].result.expectSome();
    }
});

// [Remaining tests unchanged...]
