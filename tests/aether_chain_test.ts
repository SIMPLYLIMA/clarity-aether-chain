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
    name: "Product registration and maintenance test",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        const technician = accounts.get('wallet_2')!;
        
        // Register manufacturer and technician
        let block1 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address),
            Tx.contractCall('aether-chain', 'register-technician', [
                types.principal(technician.address)
            ], manufacturer.address)
        ]);
        
        // Register product
        let block2 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'register-product', [
                types.ascii("PROD001"),
                types.ascii("Luxury Watch XYZ"),
                types.uint(52560), // 1 year warranty
                types.uint(17280)  // 4 month service interval
            ], manufacturer.address)
        ]);
        
        // Record maintenance
        let block3 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'service-product', [
                types.ascii("PROD001"),
                types.ascii("Regular maintenance completed")
            ], technician.address)
        ]);
        
        block1.receipts[0].result.expectOk();
        block1.receipts[1].result.expectOk();
        block2.receipts[0].result.expectOk();
        block3.receipts[0].result.expectOk();
        
        // Verify maintenance record
        let block4 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'get-maintenance-history', [
                types.ascii("PROD001")
            ], deployer.address)
        ]);
        
        const maintenanceHistory = block4.receipts[0].result.expectSome();
        assertEquals(maintenanceHistory.services.length, 1);
    }
});

Clarinet.test({
    name: "Warranty and service status test",
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
                types.ascii("Luxury Watch ABC"),
                types.uint(52560),
                types.uint(17280)
            ], manufacturer.address)
        ]);
        
        // Check warranty status
        let block2 = chain.mineBlock([
            Tx.contractCall('aether-chain', 'check-warranty-status', [
                types.ascii("PROD002")
            ], deployer.address),
            Tx.contractCall('aether-chain', 'service-due', [
                types.ascii("PROD002")
            ], deployer.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectBool(true);
        block2.receipts[1].result.expectOk().expectBool(false);
    }
});
