/*

	Cleaning Data in SQL Queries

*/

-- Standardize Date Format


-- This will only convert it for this query, doesn't permanently change data type

Select SaleDate, CONVERT(Date, SaleDate)
	From PortfolioProject..housingdata


-- This will permanently change the data type
Alter Table housingdata 
Alter Column Saledate DATE

Select Saledate
	From PortfolioProject..housingdata

---------------------------------------------------------------------------------------------------------------------

-- Populate Property Addess

Select PropertyAddress
	From PortfolioProject..housingdata

Select *
	From PortfolioProject..housingdata
	Where PropertyAddress is null

-- Use the ParcelID to populate some of the missing address fields
-- use uniqueID with same ParcelID to identify addresses

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
	From PortfolioProject..housingdata as a
	Join PortfolioProject..housingdata as b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
	Where a.PropertyAddress is null



-- Use ISNULL fo find NULLL values and tell it what to populate them with
-- ISNULL(find nulls in a.propertyaddress, fill them with b.propertyaddresss) that share ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
	From PortfolioProject..housingdata as a
	Join PortfolioProject..housingdata as b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
	Where a.PropertyAddress is null


-- When updating a join, you need to specify the table by its alias

UPDATE a   
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	From PortfolioProject..housingdata as a
	Join PortfolioProject..housingdata as b
		on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
	Where a.PropertyAddress is null

-- Double check to see if any NULL address values remain

Select *
	From PortfolioProject..housingdata
	Where PropertyAddress is null

----------------------------------------------------------------------------------------------------------------

-- Breaking out Address into individual Columns ( address, City, State)

Select PropertyAddress	
	From PortfolioProject..housingdata


-- Substring( what column to look at, what position to start in,(CHARINDEX('what to look for', in what column) -1 means go back one position from 'what to look for')
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
From PortfolioProject..housingdata




-- To get the city, use the location specified in CHARINDEX(',', PropertyAddress) -1) as starting position
-- and go the end, or LEN(propertyaddress)

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
From PortfolioProject..housingdata


Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) as Address
From PortfolioProject..housingdata

-- Use the above queries to create to new columns and add them to our table

ALTER TABLE housingdata
Add PropertySplitAddress Nvarchar(255);

Update housingdata
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE housingdata
Add PropertySplitCity Nvarchar(255);

Update housingdata
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

Select *
	From PortfolioProject..housingdata


-- Splitting address, city, state for owneraddress
-- This time we are going to use PARSENAME to split ip address
-- PARSENAME does stuff in reverse, so it starts at the end of the string and works backwards
Select OwnerAddress
From PortfolioProject..housingdata


Select
PARSENAME(REPLACE(Owneraddress, ',', '.'), 3),
PARSENAME(REPLACE(Owneraddress, ',', '.'), 2),
PARSENAME(REPLACE(Owneraddress, ',', '.'), 1)
From PortfolioProject..housingdata



ALTER TABLE housingdata
Add OwnerSplitAddress Nvarchar(255);

Update housingdata
SET OwnerSplitAddress = PARSENAME(REPLACE(Owneraddress, ',', '.'), 3)



ALTER TABLE housingdata
Add OwnerSplitCity Nvarchar(255);

Update housingdata
SET OwnerSplitCity = PARSENAME(REPLACE(Owneraddress, ',', '.'), 2)


ALTER TABLE housingdata
Add OwnerSplitState Nvarchar(255);

Update housingdata
SET OwnerSplitState = PARSENAME(REPLACE(Owneraddress, ',', '.'), 1)


-- Check out updates
Select *
	From PortfolioProject..housingdata

------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as Vacant' Field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject..housingdata
Group By SoldAsVacant
Order By 2

Select SoldAsVacant,
	CASE When SoldAsVacant = 'Y' Then 'Yes'
		 When SoldAsVacant = 'N' Then 'No'
		 Else SoldAsVacant
		 END
From PortfolioProject..housingdata

UPDATE housingdata
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
		 When SoldAsVacant = 'N' Then 'No'
		 Else SoldAsVacant
		 END


-----------------------------------------------------------------------------------------

-- Removing Duplicates

-- Typically you won't remove/delete raw data from a database
-- Can create a temp table and you can remove duplicaes there


-- Look for values that share ParcelID, PropertyAddress, SaleDate, SalePrice, and LegalReference


WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID) row_num

	From PortfolioProject..housingdata
		--Order BY ParcelID
)
Select *
	From RowNumCTE
	Where row_num > 1
	


WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY
					UniqueID) row_num

	From PortfolioProject..housingdata
		--Order BY ParcelID
)
DELETE
	From RowNumCTE
	Where row_num > 1


-- Delete Unused Columns

--Select *
--	From PortfolioProject..housingdata

--ALTER TABLE PortfolioProject..housingdata
--DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress