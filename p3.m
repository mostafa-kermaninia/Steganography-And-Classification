%% part 3
pred_y = TrainedModel.predictFcn(diabetestraining(:,1:6));
org_y = table2array(diabetestraining) ;
org_y = org_y(:,7) ;
pred_right = pred_y==org_y ;
accuracy = (sum(pred_right)/numel(pred_right))*100


%% part 4

pred_y2 = TrainedModel.predictFcn(diabetesvalidation(:,1:6));
org_y2 = table2array(diabetesvalidation) ;
org_y2 = org_y2(:,7) ;
pred_right2 = pred_y2==org_y2 ;
accuracy2 = (sum(pred_right2)/numel(pred_right2))*100










