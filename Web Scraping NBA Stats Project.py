#!/usr/bin/env python
# coding: utf-8

# In[36]:


from bs4 import BeautifulSoup
import requests
import pandas as pd


# In[37]:


# Define the years we want to scrape MVP data for
# Range function is non inclusive of last year

years = list(range(1991,2024))


# In[20]:


# In url, the {} replace the year, so we can iterate through the years

url_start = "https://www.basketball-reference.com/awards/awards_{}.html#mvp"


# In[18]:


# Create for loop to download the html page for every year in our list
# again {} will create a new file named for every year in our folder

for year in years:
    url = url_start.format(year)
    data = requests.get(url)
    
    with open(r"C:\Users\wrsno\Documents\NBA_MVPs/{}.html".format(year),"w+", encoding='UTF8') as f:
        f.write(data.text)


# In[23]:


# Extract data from the tables we need

with open(r"C:\Users\wrsno\Documents\NBA_MVPs\1991.html", encoding = 'UTF8') as f:
    page = f.read()


# In[31]:


soup = BeautifulSoup(page, 'html')


# In[32]:


# There is an overheader row in our table we need to remove so it will import into pandas smoothly
#  'Voting', 'PerGame', 'Shooting', and 'Advanced'

soup.find('tr', class_ = "over_header").decompose()


# In[33]:


# locate our mvp table and pull it out

mvp_table = soup.find(id = "mvp")


# In[35]:


#read mvp_table into pandas and store it as dataframe

mvp_1991 = pd.read_html(str(mvp_table))[0]


# In[42]:


# Scale up the process we used for one year using a for loop to get all the years
# append each year to the same dataframe so we end up with one dataframe containing 
# all MVP votes from 1991-2023

dfs = []
for year in years:
    with open(r"C:\Users\wrsno\Documents\NBA_MVPs\{}.html".format(year), encoding = 'UTF8') as f:
        page = f.read()
    soup = BeautifulSoup(page, 'html')
    soup.find('tr', class_ = "over_header").decompose()
    mvp_table = soup.find(id = "mvp")
    mvp = pd.read_html(str(mvp_table))[0]
    mvp["Year"] = year        # add a year column, so when dfs are combined we can still differentiate seasons
    
    dfs.append(mvp)


# In[43]:


dfs


# In[44]:


# Connect all our lists of dfs into one single dataframe

mvps = pd.concat(dfs)


# In[69]:


mvps


# In[49]:


# Save this dataframe as a csv file so we can look at it later

mvps.to_csv(r"C:\Users\wrsno\Documents\NBA_MVPs\mvps.csv")


# In[2]:


mvps = pd.read_csv(r"C:\Users\wrsno\Documents\NBA_MVPs\mvps.csv")


# In[3]:


mvps.info()


# In[11]:


# Need team stats because Wins and Losses heavily influence MVP voting

team_stats_url = "https://www.basketball-reference.com/leagues/NBA_{}_standings.html"


# In[15]:


# Create for loop to download the html page for every year in our list, this time for team stats/standings

for year in years:
    url = team_stats_url.format(year)

    data = requests.get(url)

    with open(r"C:\Users\wrsno\Documents\NBA_MVPs\teams/{}.html".format(year), "w+", encoding = "UTF8") as f:
        f.write(data.text)


# In[31]:


# as we did with the MVP voting, we are going to pull the tables of interest from the html files
# we are using the division standings table due to how it is stored in the html page


dfs = []
for year in years:
    with open(r"C:\Users\wrsno\Documents\NBA_MVPs\teams/{}.html".format(year), encoding = "UTF8") as f:
        page = f.read()

    soup = BeautifulSoup(page, 'html')
    tHeads = soup.find_all('tr', class_ = 'thead')      # find all thead items, then loop through and delete each one
    for tHead in tHeads:                                # this will remove all the thead items in our table
        tHead.decompose()                               # which include all the division labels
    team_table = soup.find(id = "divs_standings_E")
    team = pd.read_html(str(team_table))[0]
    team["Year"] = year
    team["Team"] = team["Eastern Conference"]           # reassign the conference column to team name
    del team["Eastern Conference"]                      # delete the conference column since we don't need it
    dfs.append(team)
    
    soup = BeautifulSoup(page, 'html')
    tHeads = soup.find_all('tr', class_ = 'thead')
    for tHead in tHeads:
        tHead.decompose()
    team_table = soup.find(id = "divs_standings_W")
    team = pd.read_html(str(team_table))[0]
    team["Year"] = year
    team["Team"] = team["Western Conference"]
    del team["Western Conference"]
    dfs.append(team)
    
    


# In[32]:


teams = pd.concat(dfs)


# In[33]:


teams


# In[34]:


# save our file containing all team stats from 1991-2023 to a csv file

teams.to_csv(r"C:\Users\wrsno\Documents\NBA_MVPs\teams\teams.csv")


# In[ ]:




