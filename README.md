Portfolio_ML
================
머신러닝 프로젝트 포트폴리오 정리

***
<h2> #1. Project - 이탈률을 고려한 통폐합 은행 지점 클러스터링 </h2> 

- Background 
 <p>통폐합지점 이탈에 영향을 주는 변수들을 찾고, 영업 성과 관리를 위해 변수 특성이 비슷한 지점들을 클러스터링</p>

- Summary
	<p>(1). Data Collection <br/>
		- 은행 데이터 마트(지점데이터 + 고객데이터) + 외부데이터(금융결제원)</p>
	<p>(2). Data Preprocessing <br/>
		- EDA (지점데이터 + 고객데이터 + 외부데이터) <br/>
		- Reduction (특성이 다른 지점 데이터  제거, missing value 포함한 고객데이터 제거)</p>
	<p>(3). Model & Algorithms <br/>
		- xgboost regression(지점 데이터) --> RMSE 작을 때 feature importance <br/>
		- xgboost classifier(고객 데이터) --> F1 높을 때 feature importance<br/>
		- Aggregation(고객데이터 --> 지점데이터) --> Clustering(Hierarchical, K-means, Gaussian mixture)</p>
	<p>(4). Report <br/>
		- 이탈에 영향을 주는 변수 목록 작성
		- 변수 특성이 비슷한 지점끼리 클러스터링한 결과 표 작성
	<p>(5). Review <br/>
		- 피드백 : 클러스터링보다 나은 방법이 있지 않았을까<br/>
		- Futher Research : 바뀌는 금융환경 ---> 모델링 반복 필요<br/>
		&nbsp;: 통폐합이 영향을 준 고객만을 대상으로 분석 모델을 구축해야 한다

*보러가기: [은행이탈률 클러스터링](https://github.com/hbkimhbkim/Portfolio_ML/blob/master/bankchurn/)*
      
***
<h2> #2. Project - 야구장 관객수 예측 </h2> 

***
<h2> #3. Project - 감자과자 시장분석</h2>

- Background
 <p>Text Mining(크롤링, 상관분석, 연관규칙...) --> 감자과자 시장분석</p>

- Summary

	<p>(1). Data Collection</br>
    	- 수집대상 : 오리온-포카칩 / 농심-수미칩 / 해테 - 허니버터칩 / 롯데 - 레이즈 감자칩 / PB-이마트 노브랜드 감자칩 <br/> 
    	- 수집 방법 : R을 통한 크롤링<br/>
    	- 수집 출처 : 네이버 블로그, 트위터, 페이스북</p>
    
	<p>(2). Data Preprocessing <br/>
    	- 형태소 저장 <br/>
    	- 불필요한 단어 제거 </p>
    
  	<p>(3). Model & Algorithms <br/>
	- Wordcloud : 빈도분석의 시각화를 위해<br>
    	- 상관관계 : network graph를 통해 시각화<br>
    	- graphical lasso : 추가 변수의 효과를 제어하고, 두 변수간  의 효과를 알기 위해 사용 <br>
    	- 연관규칙 : support, confidence, lift(by apriori 알고리즘)<br>
    	- 시계열 분석 : 검색 추세 분석
    
  	<p>(4). Report
    	- jupyter notebook with R로 작성

  	<p>(5). Review <br/>
    	- Feedback : 크롤링, 연관규칙, 가우시안 그래프 모델 등 다양한 분석방법을 활용할 수 있어서 좋았다 <br/>
    	- Futuer Research : 코드가 깔끔하지 않고, 명확한 결론을 내리지 못했다. 감성사전을 통해 감성분석을 하는게 필요해보인다.
		
*보러가기: [감자과자시장분석](https://github.com/hbkimhbkim/Portfolio_ML/blob/master/bankchurn/)*
