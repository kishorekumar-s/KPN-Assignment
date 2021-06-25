@isTest
public class Test_OrderProductsController {
    
    public static testMethod void testorderproduct(){

        // Insert Account
    
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
    
        // Insert Product
        Product2 p = new Product2();
        p.Name = ' Test Product ';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        // Insert Product
        Product2 p2 = new Product2();
        p2.Name = ' Test Product 2 ';
        p2.Description='Test Product Entry 2';
        p2.productCode = 'ABCD';
        p2.isActive = true;
        insert p2;
        
    
        Id pricebookId = Test.getStandardPricebookId();
        
        // Insert PricebookEntry
        list<PricebookEntry> listPriceBookEntries=new list<PricebookEntry>();
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        
        PricebookEntry standardPrice2 = new PricebookEntry();
        standardPrice2.Pricebook2Id = pricebookId;
        standardPrice2.Product2Id = p2.Id;
        standardPrice2.UnitPrice = 1;
        standardPrice2.IsActive = true;
        standardPrice2.UseStandardPrice = false;
         
        listPriceBookEntries.add(standardPrice);
        listPriceBookEntries.add(standardPrice2);
        insert listPriceBookEntries;
        // Insert Order
        
        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = a.id;
        o.Pricebook2Id =  pricebookId ;
        
        insert o;
        OrderProductsController.getAvailableProducts(o.id);
        // Insert Order Item
    
        OrderItem i = new OrderItem();
        i.OrderId = o.id;
        i.Quantity = 24;
        i.UnitPrice = 240;
        i.Product2id = p.id;
        i.PricebookEntryId=standardPrice.id;
        insert i;
        
        OrderProductsController controller= new OrderProductsController();
        OrderProductsController.getOrderProducts(o.id);
        OrderProductsController.getAvailableProducts(o.id);
        OrderProductsController.addOrderProducts(listPriceBookEntries, o.id);
        OrderProductsController.updateOrderStatus(o.id);
               
    } 
    
    public static testMethod void testorderproductNegative(){
        id orderId;
        try{
            OrderProductsController.updateOrderStatus(orderId);
            OrderProductsController.getAvailableProducts(orderId);
            
        }
        catch(Exception e)
        {
            
        }
    }
    
    
}