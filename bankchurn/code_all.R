rm(list=ls()) ; gc()
########load library###########################################################
library(dplyr); library(stringr); library(lubridate) ;library(data.table)
library(caret); library(glmnet); library(Metrics) ; library(pROC) 
library(xgboost); library(cluster); library(dbscan) ; library(mclust) ; 
library(ggplot2) ; library(factoextra) ; library(rgl); library(fpc);
library(mlbench);library(NbClust)

########load library###########################################################
setwd("R:\\10.BigData\\...\\통폐합추정이탈율분석\\DATA")

data111 <- fread('all6.csv')
unique(data111$CLSE_ORG_NM)

########basic preprocessing###########################################################
#Missing Value 
colSums(is.na(data111)) # 감소율 중 '-1'인 값은 rm tlwjadml epdlxjrk djqtsms rjtdlek

#사용층수-->integer값으로(NA는 0으로 채워넣음)
data111$USE_FLOR_CNT_CTT<-str_count(data111$USE_FLOR_CNT_CTT,',')+1

#통폐합기준 연월 날짜데이터로 바꾸기(2017-12-31일 기준으로)
a<-ymd('2017-12-31')
data111$UNFY_DT <- a-ymd(data111$UNFY_DT)
data111$UNFY_DT <- as.numeric(data111$UNFY_DT)

#폐쇄점 개절일자 날짜데이터로 바꾸기(2017-12-31일 기준으로)
a<-ymd('2017-12-31')
data111$CLSE_ORG_OPBR_DT <- a-ymd(data111$CLSE_ORG_OPBR_DT)
data111$CLSE_ORG_OPBR_DT <- as.numeric(data111$CLSE_ORG_OPBR_DT)

#1층여부 factor
data111$USE_FLOR_F1_YN<-as.factor(data111$USE_FLOR_F1_YN)

str(data111)

#label factor
data111$label <- as.factor(data111$label)

#label2 factor
data111$label2 <- as.factor(data111$label2)

#### ************************************************************** ####
########Add feature##########################
#### ************************************************************** ####

setwd('R:\\10.BigData\\캡스톤프로젝트\\20180117 고객추출데이터')
data_client <- fread('전체고객_변화추가6.csv')

#### ************************************************************** ####
#### 지점수준으로 summary                                           ####
#### ************************************************************** ####

#1. 전자금융만족여부 #2. 멤버스가입여부 #3. 담보대출만족여부 #4. 방카슈랑스만족여부
#5. 집합투자상품만족여부 #6. 퇴직연금가입여부 #7.연금보험만족여부 #8. 주택청약상품만족여부
#9. 신용대출만족여부 #10. 자동이체만족여부 #11. 스마트폰뱅킹가입여부 #12. 일반적립식만족여부
#13. 일반거치식만족여부 #14. 교차판매 보유건수(평균) #15.적립식 예금 잔액 #16. 추정소득금액
#17. 고객평점    #18. 총판매

a <-
  data_client %>%
  group_by(CLSE_ORG_NM) %>%
  mutate(ELEC_FNC_STFC_YN_summary = sum(ELEC_FNC_STFC_YN) / length(ELEC_FNC_STFC_YN),
         HANA_MBSH_NTRY_YN_summary = sum(HANA_MBSH_NTRY_YN) / length(HANA_MBSH_NTRY_YN),
         SCLON_STFC_YN_summary = sum(SCLON_STFC_YN) / length(SCLON_STFC_YN),
         BNKSR_STFC_YN_summary = sum(BNKSR_STFC_YN) / length(BNKSR_STFC_YN),
         SET_INV_PRD_STFC_YN_summary = sum(SET_INV_PRD_STFC_YN) / length(SET_INV_PRD_STFC_YN),
         RETI_PNS_NTRY_YN_summary = sum(RETI_PNS_NTRY_YN) / length(RETI_PNS_NTRY_YN),
         PNS_INSU_STFC_YN_summary = sum(PNS_INSU_STFC_YN) / length(PNS_INSU_STFC_YN),
         HOUS_SBSC_PRD_STFC_YN_summary = sum(HOUS_SBSC_PRD_STFC_YN) / length(HOUS_SBSC_PRD_STFC_YN),
         USLON_STFC_YN_summary = sum(USLON_STFC_YN) / length(USLON_STFC_YN),
         ATF_STFC_YN_summary = sum(ATF_STFC_YN) / length(ATF_STFC_YN),
         SMT_PHBK_NTRY_YN_summary = sum(SMT_PHBK_NTRY_YN) / length(SMT_PHBK_NTRY_YN),
         GEN_RSVG_STFC_YN_summary = sum(GEN_RSVG_STFC_YN) / length(GEN_RSVG_STFC_YN),
         GEN_DFRM_TP_STFC_YN_summary = sum(GEN_DFRM_TP_STFC_YN) / length(GEN_DFRM_TP_STFC_YN),
         CRSL_HOLD_NCNT_summary = mean(CRSL_HOLD_NCNT),
         RSVG_DP_BAL_summary = mean(RSVG_DP_BAL),
         ESMT_INCM_AMT_summary = mean(ESMT_INCM_AMT),
         TOTL_ASCR_summary = mean(TOTL_ASCR),
         TOTL_AMT111_summary = mean(TOTL_AMT111.y))

#######################################################
# 1번 개인고객 주거래화 코드 F / PSNL_CUST_MTRS_DV_CD_modeF
client2<-data_client

class <- client2$PSNL_CUST_MTRS_DV_CD_mode
Name_of_class <- as.character(unique(class))

onehotencoding_y <- as.data.frame(matrix(0,nrow = dim(client2)[1],ncol=length(Name_of_class)))
colnames(onehotencoding_y) <- Name_of_class

for ( i in 1:length(Name_of_class)){
  
  onehotencoding_y[as.character(client2$PSNL_CUST_MTRS_DV_CD_mode) == Name_of_class[i],i] <- 1
}

v1 <- data.frame(client2$CLSE_ORG_NM,onehotencoding_y$F,1)
fwrite(v1,'v1.csv')
v1 <- fread('v1.csv')

colnames(v1) <- c('CLSE_ORG_NM','PSNL_CUST_MTRS_DV_CD_modeF','COUNT')
v1 <- v1[,lapply(.SD, sum),by = c('CLSE_ORG_NM')]


v1$PSNL_CUST_MTRS_DV_CD_F = v1$PSNL_CUST_MTRS_DV_CD_modeF/v1$COUNT


# 2번 개인고객 주거래화 구분코드G / PSNL_CUST_MTRS_DV_CD_modeG
class <- client2$PSNL_CUST_MTRS_DV_CD_mode
Name_of_class <- as.character(unique(class))

onehotencoding_y <- as.data.frame(matrix(0,nrow = dim(client2)[1],ncol=length(Name_of_class)))
colnames(onehotencoding_y) <- Name_of_class

for ( i in 1:length(Name_of_class)){
  
  onehotencoding_y[as.character(client2$PSNL_CUST_MTRS_DV_CD_mode) == Name_of_class[i],i] <- 1
}

v2 <- data.frame(client2$CLSE_ORG_NM,onehotencoding_y$G,1)
fwrite(v2,'v2.csv')
v2 <- fread('v2.csv')

colnames(v2) <- c('CLSE_ORG_NM','PSNL_CUST_MTRS_DV_CD_modeF','COUNT')
v2 <- v2[,lapply(.SD, sum),by = c('CLSE_ORG_NM')]


v2$PSNL_CUST_MTRS_DV_CD_G = v2$PSNL_CUST_MTRS_DV_CD_modeF/v2$COUNT


# 3번 나이 / AGE_mean
class <- client2$AGE_mean
Name_of_class <- as.character(unique(class))

onehotencoding_y <- as.data.frame(matrix(0,nrow = dim(client2)[1],ncol=length(Name_of_class)))
colnames(onehotencoding_y) <- Name_of_class

for ( i in 1:length(Name_of_class)){
  
  onehotencoding_y[as.character(client2$AGE_mean) == Name_of_class[i],i] <- 1
}

v3 <- data.frame(client2$CLSE_ORG_NM,onehotencoding_y,1)
fwrite(v3,'v3.csv')
v3 <- fread('v3.csv')

colnames(v3) <- c('CLSE_ORG_NM','AGE_70대','AGE_60대','AGE_50대',
                  'AGE_40대','AGE_30대','AGE_20대','AGE_10대','COUNT')
v3 <- v3[,lapply(.SD, sum),by = c('CLSE_ORG_NM')]

v3<-
  v3 %>%
  group_by(CLSE_ORG_NM) %>%
  mutate( AGE_70비율 = AGE_70대/COUNT,
          AGE_60비율 = AGE_60대/COUNT,
          AGE_50비율 = AGE_50대/COUNT,
          AGE_40비율 = AGE_40대/COUNT,
          AGE_30비율 = AGE_30대/COUNT,
          AGE_20비율 = AGE_20대/COUNT,
          AGE_10비율 = AGE_10대/COUNT)

v3 <-
  v3 %>%
  group_by(CLSE_ORG_NM) %>%
  mutate(young = AGE_30비율 + AGE_20비율)


# 4번 개인고객 등급 코드 / PSNL_CUST_GRD_CD

class <- client2$PSNL_CUST_GRD_CD
Name_of_class <- as.character(unique(class))

onehotencoding_y <- as.data.frame(matrix(0,nrow = dim(client2)[1],ncol=length(Name_of_class)))
colnames(onehotencoding_y) <- Name_of_class

for ( i in 1:length(Name_of_class)){
  
  onehotencoding_y[as.character(client2$PSNL_CUST_GRD_CD) == Name_of_class[i],i] <- 1
}

v4 <- data.frame(client2$CLSE_ORG_NM,onehotencoding_y,1)
fwrite(v4,'v4.csv')
v4 <- fread('v4.csv')

colnames(v4) <- c('CLSE_ORG_NM','GRD1','GRD3','GRD4','GRD2','GRD9','COUNT')
v4 <- v4[,lapply(.SD, sum),by = c('CLSE_ORG_NM')]

v4$GRD1_prop = v4$GRD1/v4$COUNT
v4$GRD3_prop = v4$GRD3/v4$COUNT
v4$GRD4_prop = v4$GRD4/v4$COUNT
v4$GRD2_prop = v4$GRD2/v4$COUNT
v4$GRD9_prop = v4$GRD9/v4$COUNT

# 5번 전략세분화 등급 코드 / STGY_SEG_DV_CD

class <- client2$STGY_SEG_DV_CD
Name_of_class <- as.character(unique(class))

onehotencoding_y <- as.data.frame(matrix(0,nrow = dim(client2)[1],ncol=length(Name_of_class)))
colnames(onehotencoding_y) <- Name_of_class

for ( i in 1:length(Name_of_class)){
  
  onehotencoding_y[as.character(client2$STGY_SEG_DV_CD) == Name_of_class[i],i] <- 1
}

v5 <- data.frame(client2$CLSE_ORG_NM,onehotencoding_y,1)
fwrite(v5,'v5.csv')
v5 <- fread('v5.csv')

colnames(v5) <- c('CLSE_ORG_NM','STG1','STG4','STG6','STG2','STG3','STG5','COUNT')
v5 <- v5[,lapply(.SD, sum),by = c('CLSE_ORG_NM')]

v5$STG1_prop = v5$STG1/v5$COUNT
v5$STG4_prop = v5$STG4/v5$COUNT
v5$STG6_prop = v5$STG6/v5$COUNT
v5$STG2_prop = v5$STG2/v5$COUNT
v5$STG3_prop = v5$STG3/v5$COUNT
v5$STG5_prop = v5$STG5/v5$COUNT


###########################################################################
#################지점에 붙이기###################################
###########################################################################

# M+1 시점 데이터만 추출
datam1 <-
  data111 %>%
  filter(TERM_MM=='M1')

b<-a[,c(2,155:172)]

c<-
b %>%
  distinct(CLSE_ORG_NM, .keep_all=TRUE)
head(c)

v1<-v1[,c(1,4)]
d<-merge(c, v1, by='CLSE_ORG_NM')
head(d)

v2<-v2[,c(1,4)]
e<-merge(d,v2,by='CLSE_ORG_NM')
head(e)

v3<-v3[,c(1,17)]
f<-merge(e,v3, by='CLSE_ORG_NM')
head(f)

v4<-v4[,c(1,8,9,10,11,12)]
g<-merge(f,v4, by='CLSE_ORG_NM')
head(g)

v5<-v5[,c(1,9,10,11,12,13)]
h<-merge(g,v5, by='CLSE_ORG_NM')
head(h)

datam1<-merge(datam1,h, by='CLSE_ORG_NM')
head(datam1)

names(datam1)

############################# GRD 변수 다시 만들기  ####################################
datam1$grd <- datam1$GRD9_prop / datam1$GRD1_prop

#############################외부변수 넣기####################################
datam1$five_m <- c(17,1,20,20,4,13,6,10,17,20,11,9,9,2,8,6,11,8,6,10,
                   9,17,6,0,0,13,6,17,11,13,13,8,5,7,2,5,7,12,2,18,
                   20,2,20,9,3,3,7,10,14,11,7,6,4,4,20,1,8,9,2,20,
                   4,3,9,12,9,7,18,19,20,5,5,15,1,9,8,14,9,2,5,11,
                   13,7,11,11,16,20,11,8,8,9,8,3,4,7,1,4,13,20,3,5,
                   8,16,9,7,6,4,10,10,12,15,6,10,6,20,20,16,11,3,10,13,
                   3,3,13,8,11,5,10,10,12,14,7,7,7,7,4,10)

datam1$three_m <- c(8,0,6,16,3,6,4,6,9,10,3,8,5,2,4,6,8,6,6,10,
                    5,11,5,0,0,5,5,9,7,4,8,3,5,2,1,4,3,11,2,8,
                    15,2,20,4,2,3,3,8,5,8,5,5,3,4,15,1,5,6,1,20,
                    4,2,8,6,4,3,9,12,17,3,3,9,1,4,5,7,2,2,0,10,
                    8,2,8,4,10,19,7,4,6,3,5,2,3,3,1,2,6,10,1,3,
                    6,10,3,6,2,3,3,7,4,8,5,9,5,9,11,11,10,2,6,6,
                    2,1,7,3,6,5,4,6,10,10,6,5,5,6,1,9)

#####################지점이름에 이탈거리 붙이기#############################
datam1$CLSE_ORG_NM <- paste0(datam1$CLSE_ORG_NM,"_",datam1$label)

############수정 거리의 이탈률##############
a<-
  data111 %>%
  group_by(TERM_MM,label) %>%
  summarise(mean(ICDC_CUST_MM_CNT))

########Feature Selection##########################
#고객수를 유추하게 끔 하는 변수들 확인(CUST_NO_CNT,CUST_MM_CNT,AVG_CUST_MM_CNT,
#                                      TOTL_AMT511, TOTL_AMT512,TOTL_AMT513,TOTL_AMT514,TOTL_AMT515,
#                                      TOTL_AMT531, TOTL_AMT532,TOTL_AMT533,TOTL_AMT534)

#필요한 변수만 추출
data_hc <-datam1[,c(15,17,25,51:72,97:128)] #94는 해당 시점(M1)에는 존재하지 않기 때문에 제외
data_hc$ICDC_CUST_MM_CNT <-data_hc$ICDC_CUST_MM_CNT*100
names(data_hc)

#이탈률 적용 거리는 나머지 변수와 반대방향으로 움직임으로 변환해보자
# data_hc$WALKING2 <- max(data_hc$WALKING2) - data_hc$WALKING2

#scaling 정규화(함수만든 거에는 centering이 포함되어 있음)
# scale.features <- function(df, variables){
#   for (variable in variables){
#     df[[variable]] <- scale(df[[variable]], center = T, scale = T)
#   }
#   return(df)
# }

######상관관계 확인 --> PCA는 이미 상관관계가 높음을 가정하고 있기 떄문에######
#정규화 해주기
data_hc_s <- scale(data_hc)
data_hc_s <- as.data.frame(data_hc_s)

#이탈률 적용 거리는 나머지 변수와 반대방향으로 움직임으로 변환해보자
data_hc_s$WALKING2 <- max(data_hc_s$WALKING2) - data_hc_s$WALKING2

b <-cor(data_hc_s)
#############################PCA 분석확인####################################
#PCA 분석을 해보자
data_hc_pca <- prcomp(data_hc_s)

summary(data_hc_pca)
data_hc_pca$rotation

#scree plot을 통해 최적의 주성분 요인을 확인 --> 3개 하기
plot(prcomp(data_hc_s, type='l', sub='Scree plot'))

#biplot을 통해 지점들을 확인
biplot(prcomp(data_hc_s), cex=c(0.9,0.9))

data_pca1 <- predict(data_hc_pca)[,1]
data_pca2 <- predict(data_hc_pca)[,2]

text(data_pca1, data_pca2, labels = datam1$CLSE_ORG_NM, cex=1, pos=3, col='blue')

#####################클러스터링에 필요한 변수 추출(lm)###########################
data_hc <-datam1[,c(15,17,25,51:72)]
data_hc$ICDC_CUST_MM_CNT <-data_hc$ICDC_CUST_MM_CNT*100

set.seed(1)
index <- createDataPartition(data_hc$ICDC_CUST_MM_CNT, p=0.9, list=FALSE)
data_train <- data_hc[index,] 
data_test <- data_hc[-index,]

lm.fit<-lm(ICDC_CUST_MM_CNT~., data=data_train)
lm.test <- predict(lm.fit, newdata=data_test)
rmse(lm.test, data_test$ICDC_CUST_MM_CNT)

summary(lm.fit)

#####################클러스터링에 필요한 변수 추출(rf)###########################
data_hc <-datam1[,c(15,17,25,51:72)]
data_hc$ICDC_CUST_MM_CNT <-data_hc$ICDC_CUST_MM_CNT*100

set.seed(1)
index <- createDataPartition(data_hc$ICDC_CUST_MM_CNT, p=0.9, list=FALSE)
data_train <- data_hc[index,] 
data_test <- data_hc[-index,]

ctrl <- trainControl(method = 'repeatedcv', number=10, repeats =2,
                   verboseIter = TRUE)
rf.model <- train(ICDC_CUST_MM_CNT~., data= data_train, method = 'rf', 
                  trControl=ctrl,importance=TRUE,tuneGrid =expand.grid(mtry=15))

rf.test <- predict(rf.model, newdata = data_test)
rmse(rf.test, data_test$ICDC_CUST_MM_CNT)

importancerf <- varImp(rf.model, scale=FALSE)
plot(importancerf)

#####################클러스터링에 필요한 변수 추출(xgb)###########################
data_hc <-datam1[,c(15,17,25,51:72)]
data_hc$ICDC_CUST_MM_CNT <-data_hc$ICDC_CUST_MM_CNT*100

set.seed(1)
index <- createDataPartition(data_hc$ICDC_CUST_MM_CNT, p=0.9, list=FALSE)
data_train <- data_hc[index,] 
data_test <- data_hc[-index,]

ctrl <- trainControl(method = 'repeatedcv', number=10, repeats =2, 
                     savePredictions = TRUE,verboseIter = TRUE)
parm <- expand.grid(nrounds = 100, max_depth = 5, eta=c(0.01,0.001,0.0001),
                    gamma=0.01, colsample_bytree=0.75, min_child_weight =0,subsample=0.5)
xgb.model <- train(ICDC_CUST_MM_CNT~., data=data_train, method = 'xgbTree', trControl=ctrl, 
                   tuneGrid = parm, importance = TRUE, metric = 'RMSE')

xgb.test <- predict(xgb.model, newdata = data_test)

rmse(xgb.test, data_test$ICDC_CUST_MM_CNT)

importancexgb <- varImp(xgb.model, scale=FALSE)
plot(importancexgb)

#####################변수 중요도 그래프 ###########################
feature_imp <- function(model, title) {
  importance <- varImp(model, scale =TRUE)
  
  importance_df_1 <- importance$importance
  importance_df_1$group <- rownames(importance_df_1)
  
  importance_df_2 <- importance_df_1
  importance_df_2$Overall <-0 
  importance_df <- rbind(importance_df_1, importance_df_2)
  
  plot<-ggplot() +
  geom_point(data = importance_df_1,
             aes(x=Overall, y=group ,color=group), size =2) +
  geom_path(data=importance_df, aes(x=Overall, y=group ,color=group), size =1)+
    theme(legend.position='none')+
    labs(
      x='Importance', y='',title=title, subtitle='Feature Importance')
  return(plot)
}

feature_imp(xgb.model, 'xgboost Feature Importance')
feature_imp(rf.model, 'randomForest Feature Importance')

#####################클러스터링에 필요한 변수 추출###########################

#클러스터링에 포함되는 최종 선택 변수들 


data_hc2 <- datam1[,c('CUST_NO_CNT','young','ESMT_INCM_AMT_summary','TOTL_ASCR_summary','EMP_CNT_ALL','TOTL_AMT111_summary','AVG_TOTL_AMT132','AVG_TOTL_AMT112','RSVG_DP_BAL_summary','AVG_TOTL_AMT211',
                      'AVG_TOTL_AMT231','AVG_TOTL_AMT513','AVG_TOTL_AMT531','CRSL_HOLD_NCNT_summary','ELEC_FNC_STFC_YN_summary',
                      'HANA_MBSH_NTRY_YN_summary','SMT_PHBK_NTRY_YN_summary','BNKSR_STFC_YN_summary',
                      'PNS_INSU_STFC_YN_summary','RETI_PNS_NTRY_YN_summary','HOUS_SBSC_PRD_STFC_YN_summary',
                      'SET_INV_PRD_STFC_YN_summary','USLON_STFC_YN_summary','ATF_STFC_YN_summary','GEN_DFRM_TP_STFC_YN_summary',
                      'GEN_RSVG_STFC_YN_summary','PSNL_CUST_MTRS_DV_CD_F','PSNL_CUST_MTRS_DV_CD_G','WALKING2','three_m')]

##################### 2.계층적 클러스터링(모든변수 30개+PCA) ###########################
data_hc2 <- scale(data_hc2)
data_hc2 <- as.data.frame(data_hc2)

data_hc2$WALKING2 <- data_hc2$WALKING2*3

data_hc3 <- prcomp(data_hc2)

res <- hcut(data_hc3$x[,1:3],5,hc_method='ward.D2')
table(res$cluster)

fviz_dend(res, rect=TRUE, cex = 0.5)

a<-datam1$CLSE_ORG_NM[res$cluster==1]
b<-datam1$CLSE_ORG_NM[res$cluster==2]
c<-datam1$CLSE_ORG_NM[res$cluster==3]
d<-datam1$CLSE_ORG_NM[res$cluster==4]
e<-datam1$CLSE_ORG_NM[res$cluster==5]

mean(datam1[which(res$cluster==1),"CUST_NO_CNT"])
mean(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])

var(datam1[which(res$cluster==1),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])*10000


mean(datam1[which(res$cluster==1),"AVG_TOTL_AMT211"])

mean(datam1[which(res$cluster==1),"WALKING2"])

(mean(datam1$HANA_MBSH_NTRY_YN_summary) + mean(datam1$SMT_PHBK_NTRY_YN_summary))/2

(mean(datam1[which(res$cluster==1),"HANA_MBSH_NTRY_YN_summary"])
+ mean(datam1[which(res$cluster==1),"SMT_PHBK_NTRY_YN_summary"]))/ 2

mean(datam1[which(res$cluster==2),"CUST_NO_CNT"])

mean(datam1$TOTL_AMT211)

mean(datam1$AVG_TOTL_AMT531)


mean(datam1[which(res$cluster==4),"TOTL_AMT111_summary"])

########################클러스터링 분석###########################
a<-summary(data_hc2[which(res$cluster==1),])
b<-summary(data_hc2[which(res$cluster==2),])
c<-summary(data_hc2[which(res$cluster==3),])
d<-summary(data_hc2[which(res$cluster==4),])
e<-summary(data_hc2[which(res$cluster==5),])

boxplot(data_hc2[which(res$cluster==1),],col = 'blue')
boxplot(data_hc2[which(res$cluster==2),],col = 'blue')
boxplot(data_hc2[which(res$cluster==3),],col = 'blue')
boxplot(data_hc2[which(res$cluster==4),],col = 'blue')
boxplot(data_hc2[which(res$cluster==5),],col = 'blue')

sort(a[1,],decreasing = TRUE)[1:5]
sort(b[4,],decreasing = TRUE)[1:5]
sort(c[4,],decreasing = TRUE)[1:5]
sort(d[4,],decreasing = TRUE)[1:5]
sort(e[4,],decreasing = TRUE)[1:5]

median(data_hc2[which(res$cluster==1),"three_m"])
median(data_hc2[which(res$cluster==2),"three_m"])
median(data_hc2[which(res$cluster==3),"three_m"])
median(data_hc2[which(res$cluster==4),"three_m"])
median(data_hc2[which(res$cluster==5),"three_m"])

mean(data_hc2[which(res$cluster==1),"CUST_NO_CNT"])
mean(data_hc2[which(res$cluster==2),"CUST_NO_CNT"])
mean(data_hc2[which(res$cluster==3),"CUST_NO_CNT"])
mean(data_hc2[which(res$cluster==4),"CUST_NO_CNT"])
mean(data_hc2[which(res$cluster==5),"CUST_NO_CNT"])

data111$label3 <- 1
data111$label3[data111$CLSE_ORG_NM%in%b] <- 2
data111$label3[data111$CLSE_ORG_NM%in%c]<-3
data111$label3[data111$CLSE_ORG_NM%in%d]<-4
data111$label3[data111$CLSE_ORG_NM%in%e]<-5

a<-
data111 %>%
  group_by(TERM_MM, label3) %>%
  summarise(mean = mean(ICDC_CUST_MM_CNT))
  


#######################기존 그룹과의 차이########################################
table(datam1$label)
table(res$cluster)

table(datam1$label, res$cluster)

b3<-datam1$CLSE_ORG_NM[res$cluster==1]
b4<-datam1$CLSE_ORG_NM[res$cluster==2]
b1<-datam1$CLSE_ORG_NM[res$cluster==3]
b2<-datam1$CLSE_ORG_NM[res$cluster==4]
b5<-datam1$CLSE_ORG_NM[res$cluster==5]

a1<-datam1$CLSE_ORG_NM[datam1$label==1]
a2<-datam1$CLSE_ORG_NM[datam1$label==2]
a3<-datam1$CLSE_ORG_NM[datam1$label==3]
a4<-datam1$CLSE_ORG_NM[datam1$label==4]
a5<-datam1$CLSE_ORG_NM[datam1$label==5]
a6<-datam1$CLSE_ORG_NM[datam1$label==6]

#1 -> 1, 2->2, 3, 4, ,5->5,6
length(which(a1 %in% b1))
length(which(a2 %in% b2))
length(which(a3 %in% b3))
length(which(a4 %in% b4))
length(which(a5 %in% b5))

##################### 거리의 평균 및 분산 ###########################
mean(datam1[which(datam1$label==1),"ICDC_CUST_MM_CNT"])
mean(datam1[which(datam1$label==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(datam1$label==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(datam1$label==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(datam1$label==5),"ICDC_CUST_MM_CNT"])
mean(datam1[which(datam1$label==6),"ICDC_CUST_MM_CNT"])

var(datam1[which(datam1$label==1),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(datam1$label==2),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(datam1$label==3),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(datam1$label==4),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(datam1$label==5),"ICDC_CUST_MM_CNT"])*10000

##################### 3.계층적 클러스터링(모든변수 35개+요인분석) ###########################
data_hc2 <- scale(data_hc2)
data_hc2 <- as.data.frame(data_hc2)
data_hc3 <- factanal(data_hc2,5,rotation = 'promax', scores = 'regression')

data_hc3$loadings

res <- hcut(data_hc3$scores,5,hc_method='ward.D2')
table(res$cluster)

datam1$CLSE_ORG_NM[res$cluster==1]
datam1$CLSE_ORG_NM[res$cluster==2]
datam1$CLSE_ORG_NM[res$cluster==3]
datam1$CLSE_ORG_NM[res$cluster==4]
datam1$CLSE_ORG_NM[res$cluster==5]

mean(datam1[which(res$cluster==1),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])

var(datam1[which(res$cluster==1),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])*10000


##################### 3.계층적 클러스터링(변수 11개) ###########################
data_hc2 <- scale(data_hc2)
data_hc2 <- as.data.frame(data_hc2)
data_hc2<-prcomp(data_hc2)

res <- hcut(data_hc2,5,hc_method='ward.D2')
table(res$cluster)

fviz_dend(res, rect=TRUE, cex = 0.5)

datam1$CLSE_ORG_NM[res$cluster==1]
datam1$CLSE_ORG_NM[res$cluster==2]
datam1$CLSE_ORG_NM[res$cluster==3]
datam1$CLSE_ORG_NM[res$cluster==4]
datam1$CLSE_ORG_NM[res$cluster==5]

mean(datam1[which(res$cluster==1),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])

var(datam1[which(res$cluster==1),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==2),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==3),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==4),"ICDC_CUST_MM_CNT"])*10000
var(datam1[which(res$cluster==5),"ICDC_CUST_MM_CNT"])*10000


# #####################k-means 클러스터링###########################
# data_hc2$UNFY_DT <- 10*data_hc2$UNFY_DT
set.seed(1)
data_hc3<-as.data.frame(scale(data_hc2))
data_hc3$WALKING2<- data_hc3$WALKING2*2
kmeans_data<-kmeans(data_hc3,5, nstart = 100)
table(kmeans_data$cluster)
table(kmeans_data$cluster, datam1$label)

fviz_cluster(kmeans_data, data= scale(data_hc2),ellipse=T,
             geom='point',
             ggtheme=theme_minimal(),
             main='K-means Clustering Plot')

datam1$CLSE_ORG_NM[kmeans_data$cluster==1]
datam1$CLSE_ORG_NM[kmeans_data$cluster==2]
datam1$CLSE_ORG_NM[kmeans_data$cluster==3]
datam1$CLSE_ORG_NM[kmeans_data$cluster==4]
datam1$CLSE_ORG_NM[kmeans_data$cluster==5]

mean(datam1[which(kmeans_data$cluster==1),"ICDC_CUST_MM_CNT"])
mean(datam1[which(kmeans_data$cluster==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(kmeans_data$cluster==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(kmeans_data$cluster==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(kmeans_data$cluster==5),"ICDC_CUST_MM_CNT"])

summary(data_hc2[which(kmeans_data$cluster==2),])

# #####################k-means 클러스터링(ELbow)###########################
k.max<-15
data<-scale(data_hc2)
wss <- sapply(1:k.max, function(k){kmeans(data, k,
                                          nstart=1, iter.max=15)$tot.withinss})

wss

plot(1:k.max, wss, type='b', pch=19, frame=FALSE, xlab='Number of clusters K',
     ylab='Total within-clusters sum of squares')

#####################mclust 클러스터링###########################
data_hc2$WALKING2 <- data_hc2$WALKING2 * 2
pca_res <- prcomp(as.matrix(data_hc2))

mix_EII <- Mclust(data_hc2, 5, 'EEE') #k-means와 비슷
clust2 <- apply(mix_EII$z, 1, which.max)
plot(pca_res$x[,1:2], col=clust2)
table(clust2)

mix_VII <- Mclust(pca_res$x[,1:3], 5, 'VII')
clust3 <- apply(mix_VII$z, 1, which.max)
plot(pca_res$x[,1:2], col=clust3)
table(clust3)
table(clust3, datam1$label)

mix_EVI <- Mclust(pca_res$x[,1:3], 5, "EVI")
clust4 <- apply(mix_EVI$z, 1, which.max)
plot(pca_res$x[,1:2], col=clust4)
table(clust4)
table(clust4, datam1$label)

fviz_cluster(mix_EVI,clust4, ellipse.type = 'norm')


datam1$CLSE_ORG_NM[clust4==1]
datam1$CLSE_ORG_NM[clust4==2]
datam1$CLSE_ORG_NM[clust4==3]
datam1$CLSE_ORG_NM[clust3==4]
datam1$CLSE_ORG_NM[clust4==5]


mean(datam1[which(clust4==1),"ICDC_CUST_MM_CNT"])
mean(datam1[which(clust4==2),"ICDC_CUST_MM_CNT"])
mean(datam1[which(clust4==3),"ICDC_CUST_MM_CNT"])
mean(datam1[which(clust4==4),"ICDC_CUST_MM_CNT"])
mean(datam1[which(clust4==5),"ICDC_CUST_MM_CNT"])


table(datam1$label, clust3)

aa<--plot3d(pca_res$x[,1:3], col=clust3)

rgl.postscript('aa.ps','ps')


