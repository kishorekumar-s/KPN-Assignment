import { LightningElement,api, wire,track } from 'lwc';
import getOrderProducts from '@salesforce/apex/OrderProductsController.getOrderProducts'
import updateOrderStatus from '@salesforce/apex/OrderProductsController.updateOrderStatus'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { APPLICATION_SCOPE,subscribe,unsubscribe,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import samplemessage from "@salesforce/messageChannel/SampleMessageChannel__c";

/*Columns are assigned to the Lightning-Datatable in the HTML Component*/
const columns = [
    { label: 'Product Name', fieldName: 'ProductName'},
    { label: 'Unit Price', fieldName: 'UnitPrice',type: 'currency' },
    { label: 'Quantity', fieldName: 'Quantity',type: 'number' },
    { label: 'List Price', fieldName: 'ListPrice',type: 'currency' },
];

export default class OrderProducs extends LightningElement {
    @api recordId;
    tableData;
    order;
    columns = columns;
    wiredOrderProdList;
    /**Subscibe to the publisher */
    context=createMessageContext();
    connectedCallback(){
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.context, samplemessage, (passparam1) => {
            this.handlermethod(passparam1);
        },{scope:APPLICATION_SCOPE}
        
        );
    }
    handlermethod(passparam1){
        console.log('Request from Available Products');
        console.log(JSON.stringify(passparam1));
        

        if(this.recordId == passparam1.recordId)
        {
            refreshApex(this.wiredOrderProdList);
        }
        console.log(passparam1.recordId);
        
    }

    /*end of subscription*/
    /*wire method to get the Products related to the Order*/
    @wire (getOrderProducts, {orderId:'$recordId'})
    orderProducts(result){
        if(result.data){
            this.wiredOrderProdList = result;
            console.log('...data......',result.data);
            this.tableData = result.data;
            this.tableData = result.data.map(row=>{
                return{...row, ProductName: row.Product2.Name}
            })
        }
        else{
            console.log('...error...',result.data);
        }
    }
    /*method-Description: to update the order status to Activated*/
    activateOrder(event){
            updateOrderStatus({orderId:this.recordId})     
            .then(result => {
                console.log('...........Success');
                this.showToastMsg('Success','Record Updated','Success');
                location.reload();
            })
        .catch(error => {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            
            this.showToastMsg('Error',this.error,'Error');

        });

    }
    /*method-Description: Reusable generic method to show toast messages*/
    showToastMsg(title,msg,variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode: 'dismissable'
        })
        )
    }


}