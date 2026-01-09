"""
Snowflake Intelligence Demo - Pizzeria Bella Napoli
Interactive Cortex Analyst Interface

Deploy this as a Streamlit in Snowflake (SiS) app or run locally with:
    streamlit run streamlit_demo.py
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import json

# Page configuration
st.set_page_config(
    page_title="Bella Napoli - AI Analytics",
    page_icon="🍕",
    layout="wide"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        color: #D32F2F;
        font-weight: bold;
    }
    .sub-header {
        font-size: 1.2rem;
        color: #666;
    }
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        padding: 20px;
        border-radius: 10px;
        color: white;
    }
    .stTextInput input {
        font-size: 1.1rem;
    }
</style>
""", unsafe_allow_html=True)

# Initialize session
@st.cache_resource
def get_session():
    try:
        return get_active_session()
    except:
        # For local development, you'd configure connection here
        st.error("Please run this app in Snowflake Streamlit in Snowflake (SiS)")
        return None

session = get_session()

# Header
col1, col2 = st.columns([1, 5])
with col1:
    st.markdown("# 🍕")
with col2:
    st.markdown('<p class="main-header">Bella Napoli Analytics</p>', unsafe_allow_html=True)
    st.markdown('<p class="sub-header">Powered by Snowflake Intelligence</p>', unsafe_allow_html=True)

st.divider()

# Sidebar
with st.sidebar:
    st.image("https://www.snowflake.com/wp-content/themes/flavor/flavor/assets/img/logo-dark.svg", width=200)
    st.markdown("### Demo Features")
    
    demo_mode = st.radio(
        "Select Feature",
        ["💬 Ask Questions (Cortex Analyst)", 
         "😊 Sentiment Analysis",
         "📊 Sales Forecast",
         "🎯 Customer Segments",
         "📈 Live Dashboard"]
    )
    
    st.divider()
    st.markdown("### Sample Questions")
    st.markdown("""
    - What were our top 5 pizzas last month?
    - Compare revenue by location
    - Show daily order trends
    - Who are our best customers?
    - What's our average order value?
    """)

# Main content area
if demo_mode == "💬 Ask Questions (Cortex Analyst)":
    st.markdown("## 💬 Ask Questions in Natural Language")
    st.markdown("Use Cortex Analyst to query your data without writing SQL")
    
    # Question input
    user_question = st.text_input(
        "Ask a question about your pizza business:",
        placeholder="e.g., What were our top selling pizzas this month?",
        key="analyst_question"
    )
    
    col1, col2 = st.columns([1, 4])
    with col1:
        ask_button = st.button("🔍 Ask", type="primary", use_container_width=True)
    
    if ask_button and user_question:
        with st.spinner("Analyzing your question..."):
            try:
                # Call Cortex Analyst
                analyst_query = f"""
                SELECT SNOWFLAKE.CORTEX.ANALYST(
                    '@PIZZERIA_DEMO.BELLA_NAPOLI.SEMANTIC_MODELS/04_semantic_model.yaml',
                    '{user_question.replace("'", "''")}'
                ) AS response
                """
                result = session.sql(analyst_query).collect()
                response = json.loads(result[0]['RESPONSE'])
                
                # Display generated SQL
                if 'sql' in response:
                    with st.expander("📝 Generated SQL", expanded=False):
                        st.code(response['sql'], language='sql')
                
                # Execute the generated SQL and show results
                if 'sql' in response:
                    data = session.sql(response['sql']).to_pandas()
                    st.dataframe(data, use_container_width=True)
                    
                    # Show natural language answer if available
                    if 'answer' in response:
                        st.success(response['answer'])
                        
            except Exception as e:
                st.error(f"Error: {str(e)}")
                st.info("Make sure the semantic model is uploaded to the stage.")

elif demo_mode == "😊 Sentiment Analysis":
    st.markdown("## 😊 Customer Review Sentiment Analysis")
    
    # Fetch recent reviews with sentiment
    sentiment_query = """
    SELECT 
        review_id,
        overall_rating,
        review_text,
        ROUND(SNOWFLAKE.CORTEX.SENTIMENT(review_text), 3) AS sentiment_score
    FROM PIZZERIA_DEMO.BELLA_NAPOLI.FACT_REVIEW
    WHERE review_text IS NOT NULL
    ORDER BY review_date DESC
    LIMIT 20
    """
    
    with st.spinner("Analyzing sentiment..."):
        try:
            df = session.sql(sentiment_query).to_pandas()
            
            # Add sentiment labels
            df['Sentiment'] = df['SENTIMENT_SCORE'].apply(
                lambda x: '😊 Positive' if x >= 0.3 else ('😞 Negative' if x <= -0.3 else '😐 Neutral')
            )
            
            # Summary metrics
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                avg_sentiment = df['SENTIMENT_SCORE'].mean()
                st.metric("Avg Sentiment", f"{avg_sentiment:.2f}")
            with col2:
                positive_pct = (df['SENTIMENT_SCORE'] >= 0.3).mean() * 100
                st.metric("Positive %", f"{positive_pct:.0f}%")
            with col3:
                negative_pct = (df['SENTIMENT_SCORE'] <= -0.3).mean() * 100
                st.metric("Negative %", f"{negative_pct:.0f}%")
            with col4:
                avg_rating = df['OVERALL_RATING'].mean()
                st.metric("Avg Rating", f"{avg_rating:.1f} ⭐")
            
            st.divider()
            
            # Display reviews
            for _, row in df.iterrows():
                with st.container():
                    col1, col2 = st.columns([4, 1])
                    with col1:
                        st.markdown(f"**Review #{row['REVIEW_ID']}** ({row['OVERALL_RATING']}⭐)")
                        st.write(row['REVIEW_TEXT'][:200] + "..." if len(str(row['REVIEW_TEXT'])) > 200 else row['REVIEW_TEXT'])
                    with col2:
                        st.markdown(f"### {row['Sentiment']}")
                        st.caption(f"Score: {row['SENTIMENT_SCORE']}")
                    st.divider()
                    
        except Exception as e:
            st.error(f"Error: {str(e)}")

elif demo_mode == "📊 Sales Forecast":
    st.markdown("## 📊 Sales Forecasting")
    
    forecast_days = st.slider("Forecast horizon (days)", 7, 30, 14)
    
    if st.button("Generate Forecast", type="primary"):
        with st.spinner("Training forecast model..."):
            try:
                # Create forecast model
                session.sql("""
                    CREATE OR REPLACE SNOWFLAKE.ML.FORECAST demo_forecast(
                        INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'PIZZERIA_DEMO.BELLA_NAPOLI.FACT_DAILY_SALES'),
                        TIMESTAMP_COLNAME => 'SALES_DATE',
                        TARGET_COLNAME => 'TOTAL_REVENUE',
                        SERIES_COLNAME => 'LOCATION_ID'
                    )
                """).collect()
                
                # Generate forecast
                session.sql(f"""
                    CALL demo_forecast!FORECAST(FORECASTING_PERIODS => {forecast_days})
                """).collect()
                
                # Get results
                forecast_df = session.sql("""
                    SELECT 
                        l.location_name,
                        f.ts AS forecast_date,
                        f.forecast,
                        f.lower_bound,
                        f.upper_bound
                    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) f
                    JOIN PIZZERIA_DEMO.BELLA_NAPOLI.DIM_LOCATION l 
                        ON f.series::INT = l.location_id
                    ORDER BY l.location_name, f.ts
                """).to_pandas()
                
                # Plot
                import plotly.express as px
                fig = px.line(
                    forecast_df, 
                    x='FORECAST_DATE', 
                    y='FORECAST',
                    color='LOCATION_NAME',
                    title='Revenue Forecast by Location'
                )
                st.plotly_chart(fig, use_container_width=True)
                
                # Table
                st.dataframe(forecast_df, use_container_width=True)
                
            except Exception as e:
                st.error(f"Error: {str(e)}")

elif demo_mode == "🎯 Customer Segments":
    st.markdown("## 🎯 Customer Segmentation (RFM Analysis)")
    
    rfm_query = """
    WITH rfm AS (
        SELECT 
            c.customer_id,
            c.first_name || ' ' || c.last_name AS customer_name,
            c.email,
            DATEDIFF(DAY, MAX(o.order_timestamp), CURRENT_DATE()) AS recency,
            COUNT(*) AS frequency,
            SUM(o.total_amount) AS monetary
        FROM PIZZERIA_DEMO.BELLA_NAPOLI.DIM_CUSTOMER c
        JOIN PIZZERIA_DEMO.BELLA_NAPOLI.FACT_ORDER o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id, c.first_name, c.last_name, c.email
    )
    SELECT 
        customer_name,
        email,
        recency AS days_since_last_order,
        frequency AS total_orders,
        ROUND(monetary, 2) AS lifetime_value,
        CASE 
            WHEN recency < 30 AND frequency >= 5 AND monetary >= 200 THEN 'Champion'
            WHEN recency < 60 AND frequency >= 3 THEN 'Loyal'
            WHEN recency > 90 AND monetary >= 100 THEN 'At Risk'
            WHEN recency > 120 THEN 'Lost'
            ELSE 'Regular'
        END AS segment
    FROM rfm
    ORDER BY monetary DESC
    LIMIT 50
    """
    
    with st.spinner("Segmenting customers..."):
        try:
            df = session.sql(rfm_query).to_pandas()
            
            # Segment counts
            segment_counts = df['SEGMENT'].value_counts()
            
            col1, col2 = st.columns(2)
            
            with col1:
                import plotly.express as px
                fig = px.pie(
                    values=segment_counts.values, 
                    names=segment_counts.index,
                    title='Customer Segments',
                    color_discrete_sequence=px.colors.qualitative.Set2
                )
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                st.markdown("### Segment Summary")
                for segment in ['Champion', 'Loyal', 'Regular', 'At Risk', 'Lost']:
                    count = segment_counts.get(segment, 0)
                    emoji = {'Champion': '⭐', 'Loyal': '💚', 'Regular': '👋', 'At Risk': '⚠️', 'Lost': '👻'}.get(segment, '')
                    st.metric(f"{emoji} {segment}", count)
            
            st.divider()
            st.markdown("### Customer Details")
            st.dataframe(df, use_container_width=True)
            
        except Exception as e:
            st.error(f"Error: {str(e)}")

elif demo_mode == "📈 Live Dashboard":
    st.markdown("## 📈 Live Operations Dashboard")
    
    # Today's metrics
    today_query = """
    SELECT 
        COUNT(DISTINCT order_id) AS orders_today,
        ROUND(SUM(total_amount), 2) AS revenue_today,
        ROUND(AVG(total_amount), 2) AS avg_order
    FROM PIZZERIA_DEMO.BELLA_NAPOLI.FACT_ORDER
    WHERE DATE(order_timestamp) = CURRENT_DATE()
    """
    
    # Location breakdown
    location_query = """
    SELECT 
        l.location_name,
        COUNT(DISTINCT o.order_id) AS orders,
        ROUND(SUM(o.total_amount), 2) AS revenue
    FROM PIZZERIA_DEMO.BELLA_NAPOLI.FACT_ORDER o
    JOIN PIZZERIA_DEMO.BELLA_NAPOLI.DIM_LOCATION l ON o.location_id = l.location_id
    WHERE DATE(o.order_timestamp) >= DATEADD(DAY, -7, CURRENT_DATE())
    GROUP BY l.location_name
    ORDER BY revenue DESC
    """
    
    try:
        # Today's summary
        st.markdown("### Today's Performance")
        today_df = session.sql(today_query).to_pandas()
        
        col1, col2, col3 = st.columns(3)
        with col1:
            st.metric("Orders Today", today_df['ORDERS_TODAY'].iloc[0] if len(today_df) > 0 else 0)
        with col2:
            st.metric("Revenue Today", f"${today_df['REVENUE_TODAY'].iloc[0]:,.0f}" if len(today_df) > 0 else "$0")
        with col3:
            st.metric("Avg Order", f"${today_df['AVG_ORDER'].iloc[0]:,.2f}" if len(today_df) > 0 else "$0")
        
        st.divider()
        
        # Location performance (last 7 days)
        st.markdown("### Last 7 Days by Location")
        location_df = session.sql(location_query).to_pandas()
        
        import plotly.express as px
        fig = px.bar(
            location_df, 
            x='LOCATION_NAME', 
            y='REVENUE',
            color='LOCATION_NAME',
            title='Revenue by Location (Last 7 Days)'
        )
        st.plotly_chart(fig, use_container_width=True)
        
    except Exception as e:
        st.error(f"Error: {str(e)}")

# Footer
st.divider()
st.markdown("""
<div style='text-align: center; color: #888;'>
    <small>Snowflake Intelligence Demo | Pizzeria Bella Napoli | Data is synthetic</small>
</div>
""", unsafe_allow_html=True)
