/**
* @author Kishore Kumar Salla
* @date 25 June 2021
*
* Class Name: OrderProductsController
* @description OrderProductsController is the controller for OrderProducts and AvailableProducts Lightning Web Components
*/
public with sharing class OrderProductsController {
    
    /*******************************************************************************************************
    * @description Accepts the OrderId and fetch the OrderItems. This method is used in OrderProducts LWC Component
    * returns list of OrderItems.
    */
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderProducts(Id orderId){
        return [ SELECT Id,UnitPrice,ListPrice,Quantity,Product2.Name,OrderId FROM OrderItem
        WHERE OrderId =:orderId];
    }
    /*******************************************************************************************************
    * @description Accepts the OrderId and fetch the PricebookEntry. This method is used in availableProducts LWC Component
    * returns list of PricebookEntries.
    */
    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getAvailableProducts(Id orderId){
        try {
                order ord;
                Id pricBookId;
                list<order> listOrder=[select id,Pricebook2Id from Order where id=:orderId];
                list<PricebookEntry> lstPriceBooks=new list<PricebookEntry>();
                list<PricebookEntry> lstFnlPriceBooks=new list<PricebookEntry>();
                list<PricebookEntry> tempList=new list<PricebookEntry>();
                set<Id> prodIdSet=new set<Id>();
                if(!listOrder.isEmpty())
                {
                    ord=listOrder[0];
                    pricBookId=ord.Pricebook2Id;
                    
                }    
                //Query for the existing orderItems - this is to show the existing orderItems on the top of available produts
                for(OrderItem oItem: [select id,Product2.Id from orderItem where orderId=:ord.id])
                {
                    prodIdSet.add(oItem.Product2.Id);
                }
                //Query the list of PriceBookEntry records sutiable with the Order-PriceBook 
                lstPriceBooks=[ SELECT Id,UnitPrice,product2.Id,Product2.Name,Pricebook2Id,Pricebook2.IsStandard FROM PricebookEntry
                WHERE Pricebook2Id=:pricBookId];
                if(prodIdSet.isEmpty())
                {
                    return lstPriceBooks; //If there are no OrderItems on the Order simply return the PriceBookEntries
                }
                for(PriceBookEntry entry:lstPriceBooks)
                {
                    if(prodIdSet.contains(entry.product2.Id)) //check if the ProductId is already available in the existing OrderItems
                        lstFnlPriceBooks.add(entry);
                    else
                        tempList.add(entry);     //Temporary list to add the delta of suggested products                   
                }
                lstFnlPriceBooks.addAll(tempList);
                return lstFnlPriceBooks; //return final list of products that are added to Order + suggested products 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*******************************************************************************************************
    * @description Accepts the OrderId to update the status to Activated. This method is used in orderProducts LWC Component
    * returns void.
    */
    @AuraEnabled
    public static void updateOrderStatus(Id orderId){
        try {
            System.debug('orderId......'+orderId);
            update new Order (Id=orderId,Status='Activated');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*******************************************************************************************************
    * @description Accepts the OrderId and list of PricebookEntry Records. It performs an upsertion operation on OrderItems invoked by availableProducts LWC.
    * returns void
    */
    @AuraEnabled
    public static void addOrderProducts(List<PricebookEntry> selectedProdLst,Id orderId){
        List<OrderItem> orderItemLst = new List<OrderItem> ();
        OrderItem orderProd;
        map<Id,OrderItem> mapProdIdOrderItem=addOrderItems(orderId); //existing order Items are returned
        try {
            for(PricebookEntry prod: selectedProdLst){
                if(mapProdIdOrderItem.containsKey(prod.Product2.Id)) //check if productID is already part of OrderItems
                {
                    orderProd=mapProdIdOrderItem.get(prod.Product2.Id); 
                    orderProd.Quantity+=1; //Increase the quantity- this is controll the redundant entry in OrderItems
                }else {
                    //Create a new OrderItem
                    orderProd = new OrderItem(
                    PricebookEntryId = prod.Id,
                    Quantity = 1,
                    unitPrice = prod.UnitPrice,
                    OrderId = orderId 
                    );
                }
                
                orderItemLst.add(orderProd);
            }
            Database.upsert(orderItemLst,true); //Upserting the Order Items
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*******************************************************************************************************
    * Method Name: addOrderItems
    * @description Accepts the OrderId and returns map (ProductId and related Order Item)
    * returns map (ProductId and related Order Item)
    */
    public static map<Id,OrderItem> addOrderItems(Id orderId)
    {
        map<Id,OrderItem> mapProdIdOrderItem=new map<Id,OrderItem>();
        for(OrderItem item: [SELECT Id,UnitPrice,ListPrice,Quantity,Product2.Name,OrderId,Product2Id FROM OrderItem
        WHERE OrderId =:orderId])
        {
            mapProdIdOrderItem.put(item.Product2Id,item);
        }
        return mapProdIdOrderItem;
    }

    

}