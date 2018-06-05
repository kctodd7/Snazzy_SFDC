/********************************************************************
    Written By: Kelly Todd 
    Date: 12/03/2014
    Purpose: All Account Trigger logic located here.  
    
    NOTE: The below calls are wrapped in try/catches.  This is because they are
    	  future/callouts that cannot be called from other future/callouts which we currently
    	  have some of.
    
    	  1) Update the cobb website for dealers when an SFDC Account changes
    	  2) Create an associated Netsuite account when a Dealer account becomes Authorized
    	  3) Update Netsuite Accounts with SFDC data
********************************************************************/
trigger Accounts on Account (after insert, after update) 
{

	//some of the fields aren't coming through with just trigger.new and trigger.old
	//so just grabbing the values
	Account [] newAccountList = trigger.new;
	Account [] oldAccountList = trigger.old;

	/* 1. UPDATE DEALER WEBSITE      */		
	if(!TriggerTracker.triggerHasAlreadyExecuted('Accounts_DealerWebsiteUpdate'))
	{
		boolean updateAccounts = false;	
		if (trigger.isAfter)
		{
			system.debug('Updating Dealer Website - Trigger Entry');
			
			TriggerTracker.setTriggerUsed('Accounts_DealerWebsiteUpdate');
					
			if (trigger.isInsert)
			{
				for (Account dealerAccount: newAccountList)
				{
					if (dealerAccount.dealer_status__c.contains('Authorized') && 
						dealerAccount.Latitude_Coordinates__c != null &&
						dealerAccount.Longitude_Coordirnates__c != null)
					{
						system.debug('Updating Dealer Website - Insert Triggered');
						updateAccounts = true;
						break;
					}
				}
			}
			else if (trigger.isUpdate)
			{	
				for(Integer i=0 ; i < newAccountList.size() ; i++)
				{
					if (
							oldAccountList[i].dealer_status__c != newAccountList[i].dealer_status__c ||
							oldAccountList[i].Latitude_Coordinates__c != newAccountList[i].Latitude_Coordinates__c ||
							oldAccountList[i].Longitude_Coordirnates__c != newAccountList[i].Longitude_Coordirnates__c ||
							oldAccountList[i].Website != newAccountList[i].Website ||
							oldAccountList[i].Phone != newAccountList[i].Phone ||
							oldAccountList[i].BillingCity != newAccountList[i].BillingCity ||
							oldAccountList[i].BillingCountry != newAccountList[i].BillingCountry ||
							oldAccountList[i].BillingState != newAccountList[i].BillingState ||
							oldAccountList[i].BillingStreet != newAccountList[i].BillingStreet ||
							oldAccountList[i].BillingPostalCode != newAccountList[i].BillingPostalCode || 
							oldAccountList[i].recordtypeid != newAccountList[i].recordtypeid ||
							oldAccountList[i].Capabilities__c != newAccountList[i].Capabilities__c ||
							oldAccountList[i].vehicles_supported__c != newAccountList[i].vehicles_supported__c ||
							oldAccountList[i].Website_redirect__c != newAccountList[i].Website_redirect__c
						)
					{
						system.debug('Updating Dealer Website - Update Triggered');
						updateAccounts = true;
						break;
					}
	        	}
			}
		}			 							 
		
		if (updateAccounts)
		{
			system.debug ('Updating Accounts On Dealer Page');
			
			try
			{
				Accounts.updateDealerAccountsOnCobbWebsite();
			}
			catch (Exception ex)
			{
				system.debug('Trigger: Error updating Website for Accounts: ' + ex + ' ' + ex.getStackTraceString());
			}	
		}			 
	}
	/* END UPDATE DEALER WEBSITE 	*/
	
	/* 2. CREATE NETSUITE ACCOUNT      */		
	if(!TriggerTracker.triggerHasAlreadyExecuted('Accounts_CreateNetsuiteAccount'))
	{
		set<id> NSCreateAccountIds = new set<id>();
		
		if (trigger.isAfter)
		{
			system.debug('Creating Netsuite Accounts');
			
			TriggerTracker.setTriggerUsed('Accounts_CreateNetsuiteAccount');
					
			if (trigger.isInsert || trigger.isUpdate)
			{
				for (Account NSCreateAccount: trigger.new)
				{
					if (NSCreateAccount.dealer_status__c.contains('Authorized') && 
						null == NSCreateAccount.netsuite_id__c)
					{
						system.debug('Updating Dealer Website - Insert Triggered');
						NSCreateAccountIds.add(NSCreateAccount.id);
					}
				}
			}
		}			 							 
		
		if (NSCreateAccountIds.size() > 0)
		{
			system.debug ('Creating Accounts in Netsuite: ' + NSCreateAccountIds.size());
			
			try
			{
				Netsuite.createAccounts(NSCreateAccountIds);
			}
			catch (Exception ex)
			{
				system.debug('Trigger: Error Adding Accounts to Netsuite: ' + ex + ' ' + ex.getStackTraceString());
			}	
		}			 
	}
	/* END CREATE NETSUITE ACCOUNT  	*/
	
	/* 3. UPDATE NETSUITE ACCOUNT      */		
	if(!TriggerTracker.triggerHasAlreadyExecuted('Accounts_UpdateNetsuiteAccount'))
	{
		set<id> updateAccountIds = new set<id>();
		
		if (trigger.isAfter)
		{
			system.debug('Updating Netsuite Accounts');
			
			TriggerTracker.setTriggerUsed('Accounts_UpdateNetsuiteAccount');
					
			if (trigger.isUpdate)
			{
				for(Integer i=0 ; i < newAccountList.size() ; i++)
				{
					system.debug ('old Tier: ' + oldAccountList[i].Tier__c + ' New Tier: ' + newAccountList[i].Tier__c + ' NS: ' + newAccountList[i].netsuite_id__c);
					if (oldAccountList[i].tier__c != newAccountList[i].tier__c && 
						null != newAccountList[i].netsuite_id__c)
					{
						system.debug('Updating Netsuite Account: ' + newAccountList[i].id);
						updateAccountIds.add(newAccountList[i].id);
					}
				}
			}
		}			 							 
		
		if (updateAccountIds.size() > 0)
		{
			system.debug ('Updating Accounts in Netsuite: ' + updateAccountIds.size());
			
			try
			{
				Netsuite.updateAccounts(updateAccountIds);
			}
			catch (Exception ex)
			{
				system.debug('Trigger: Error Updating Accounts to Netsuite: ' + ex + ' ' + ex.getStackTraceString());
			}	
		}			 
	}
	/* END UPDATE NETSUITE ACCOUNT  	*/


}