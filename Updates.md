# Changes needed 

## Issue 1 
>> Resolved - Testted and working with default listner all the time 
while modifying the alb listner using a listner arn of https
forwardig the traffic to another target group will leads to disaster becasue we have 2 listner rule in https rule
1 is default and another is for hostheader 
- need to modify the traffic switch configuration to use a specific listenr for the traffic switch 

## Issue 2
>>
- while modifying the alb listner to forward the traffic to another target group 50/50 using the script 
then this script will update the default `group level stikenss` configuration in default listner to `false`
- need to update the traffic switch configuration to use use a 1 hour group level stickness for the default listner rule 
- there might be more things that will get removed while traffic switch like ssh certificate & security policy 
>> Resolution
To update the listener's default actions without affecting other configurations such as stickiness settings, you can retrieve the existing listener configuration, modify only the necessary parts, and then apply the updated configuration. Here's how you can do it:

1. Retrieve the current listener configuration.
2. Modify the default actions to balance traffic between TG1 and TG2 while keeping other configurations intact.
3. Apply the updated listener configuration.

Here's a sample script to achieve this:

```bash
# Step 1: Retrieve current listener configuration
current_config=$(aws elbv2 describe-listeners --listener-arns $ALB_LISTENER_ARN --query 'Listeners[0].DefaultActions')

# Step 2: Modify default actions to balance traffic between TG1 and TG2
updated_config=$(echo $current_config | jq '.[0].ForwardConfig.TargetGroups[0].Weight=50 | .[0].ForwardConfig.TargetGroups[1].Weight=50')

# Step 3: Apply the updated listener configuration
aws elbv2 modify-listener \
  --listener-arn $ALB_LISTENER_ARN \
  --default-actions "$updated_config"
```

This script retrieves the current default actions of the specified listener, modifies the target group weights to balance traffic between TG1 and TG2, and then applies the updated configuration without affecting other settings like stickiness configurations. Make sure to have `jq` installed to manipulate JSON data in the script. Adjust the weights and other parameters as per your requirements.