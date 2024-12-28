import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Manufacturer registration test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Product registration and transfer test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        const dealer = accounts.get('wallet_2')!;
        
        // Register manufacturer
        let block1 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address)
        ]);
        
        // Register dealer
        let block2 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-dealer', [
                types.principal(dealer.address)
            ], manufacturer.address)
        ]);
        
        // Register product
        let block3 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-product', [
                types.ascii("PROD001"),
                types.ascii("Luxury Watch XYZ")
            ], manufacturer.address)
        ]);
        
        // Transfer product
        let block4 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'transfer-product', [
                types.ascii("PROD001"),
                types.principal(dealer.address)
            ], manufacturer.address)
        ]);
        
        block1.receipts[0].result.expectOk();
        block2.receipts[0].result.expectOk();
        block3.receipts[0].result.expectOk();
        block4.receipts[0].result.expectOk();
        
        // Verify product info
        let block5 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'get-product-info', [
                types.ascii("PROD001")
            ], deployer.address)
        ]);
        
        const productInfo = block5.receipts[0].result.expectSome();
        assertEquals(productInfo.current-owner, dealer.address);
    }
});

Clarinet.test({
    name: "Authentication verification test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        
        // Register manufacturer and product
        let block = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address),
            Tx.contractCall('aether-chain', 'register-product', [
                types.ascii("PROD002"),
                types.ascii("Luxury Bag ABC")
            ], manufacturer.address)
        ]);
        
        // Verify authenticity
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('aether-chain', 'verify-authenticity', [
                types.ascii("PROD002")
            ], deployer.address)
        ]);
        
        verifyBlock.receipts[0].result.expectOk().expectBool(true);
    }
});