# Business Central – Shopify Integration

Custom integration between Microsoft Dynamics 365 Business Central On-Prem
and Shopify, developed as part of a master's thesis.

## Overview

The solution is implemented as a Microsoft Dynamics 365 Business Central
AL extension and communicates with Shopify through the Admin GraphQL API.

### Implemented functionality

- Product and price synchronization from Business Central to Shopify
- Inventory synchronization
- Product / Variant / Inventory Item mapping
- Shopify order import into Business Central
- Order Buffer and retry mechanism
- Duplicate-order protection
- Order total validation
- Background synchronization using Business Central Job Queue
- BC-IMPORTED order tagging
- Integration logging, validation and audit snapshot

## Technologies

- Microsoft Dynamics 365 Business Central On-Prem BC27
- AL (Application Language)
- Shopify Admin GraphQL API
- Visual Studio Code

## Architecture

Business Central acts as the authoritative source for products, prices and
physical inventory. Shopify acts as the customer-facing sales channel and
source of online orders.

## Security

Credentials, access tokens and Client Secret values are not included in this
repository.

## Academic context

This implementation was developed as the practical part of the master's thesis:

**Integracija poslovne aplikacije i ERP sustava**

University of Zagreb  
Faculty of Organization and Informatics  
2026

## Author

Nimaj Dupanović
