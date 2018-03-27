<h1> Portfolio </h1>
프로필 및 포트폴리오 정리
<hr>
<h2> #1. Project - 이탈률을 고려한 통폐합 은행 지점 클러스터링 </h2> 

- Background 
 <p>통폐합지점 이탈에 영향을 주는 변수들을 찾고, 영업 성과 관리를 위해 변수 특성이 비슷한 지점들을 클러스터링</p>

- Summary
<p>&nbsp;&nbsp;(1). Data Collection <br>
         - 은행 데이터 마트(지점데이터 + 고객데이터) + 외부데이터(금융결제원)</p>
<p>&nbsp;&nbsp;(2). Data Preprocessing <br>
         - EDA (지점데이터 + 고객데이터 + 외부데이터)<br>
         - Reduction (특성이 다른 지점 데이터  제거, missing value 포함한 고객데이터 제거)</p>
<p>&nbsp;&nbsp;(3). Model & Algorithms <br>
         - xgboost regression(지점 데이터) --> parameter tuning --> RMSE 작을 때 feature importance <br>
         - xgboost classifier(고객 데이터) --> parameter tuning --> F1 높을 때 feature importance

<p>&nbsp;&nbsp;(1). Data collection <br>
         - 은행 데이터 마트(지점데이터 + 고객데이터) + 외부데이터(금융결제원)</p>
<p>&nbsp;&nbsp;(1). Data collection <br>
         - 은행 데이터 마트(지점데이터 + 고객데이터) + 외부데이터(금융결제원)</p>

         
         
<h2> #2. Project - 야구장 관객수 예측 </h2> 
