import { LightningElement, wire, api} from 'lwc';
import getAvailableProducts from '@salesforce/apex/OrderProductsController.getAvailableProducts';
import addOrderProducts from '@salesforce/apex/OrderProductsController.addOrderProducts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { publish,createMessageContext,releaseMessageContext } from 'lightning/messageService';
import samplemessage from "@salesforce/messageChannel/SampleMessageChannel__c";
/*Columns are assigned to the Lightning-Datatable in the HTML Component*/
const columns = [
    { label: 'Product Name', fieldName: 'ProductName'},
    { label: 'List Price', fieldName: 'UnitPrice',type: 'currency' },
];
const FIELDS = ['Order.Status'];
export default class AvailableProducts extends LightningElement {
    tableData;
    @api recordId;
    columns = columns;
    selectedRows;
    order;
    context=createMessageContext();
    availableProdsWire;
    /*wire method to get the Order record and its Status*/
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
    getOrderDetails(result) {
        
        if (result.error) {
            
        } else if (result.data) {
            this.order = result.data;
        }
    }
    /*wire method to get procuts based onthe Pricebook sorted with the list of products available on the order*/
    @wire (getAvailableProducts,{orderId:'$recordId'})
    allProducts(result){
        this.availableProdsWire=result;
        if(result.data){
            console.log('...data...Available...',result.data);
            this.tableData = result.data;
            this.tableData = result.data.map(row=>{
                return{...row, ProductName: row.Product2.Name}
            })
        }
        else{
            console.log('...error...',result.error);
        }
    }
    /*Method to assign the products selected inthe lightning Data table*/
    getSelectedProducts(event) {
        this.selectedRows = event.detail.selectedRows;
        console.log('selectedRows......',this.selectedRows);
    }

    
    /*Method to fetch the products selected inthe lightning Data table and Send it to the Controller to Upsert the records*/
    getSelectedName(event) {
        
        console.log('this.order......',this.order);
        if(this.order.fields.Status.value == 'Activated'){
            this.showToastMsg('Error','The Order is currently in Activated Status. Products cannot be added to this Order.','Error');
            return;
        }
        
        
        if(this.selectedRows==undefined || this.selectedRows.length==0){
            this.showToastMsg('Error','Please select atleast one product.','Error');
            return;
        }

        // Display that fieldName of the selected rows
        console.log('selectedRows......',this.selectedRows);
        console.log('selectedRows...zero...',this.selectedRows[0]);
        addOrderProducts({selectedProdLst:this.selectedRows,orderId:this.recordId})
        .then(result => {
            console.log('...........Success');
            debugger;
            refreshApex(this.availableProdsWire);
            this.showToastMsg('Success','Record Updated','Success');
            this.template.querySelector('lightning-datatable').maxRowSelection=0
            this.template.querySelector('lightning-datatable').maxRowSelection=this.tableData.length
            /***send message via lightning service */
            const passparam1={
                recordId:this.recordId,
                recordData:'Products added Successfully onthe published record'
            };
            publish(this.context,samplemessage,passparam1)
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