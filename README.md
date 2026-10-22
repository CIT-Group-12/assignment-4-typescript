Assignment 4: TypeScript

Course: Complex IT Systems – Theory E2026 (40417)
Section: Backend development

This repository contains our group's solutions to Assignment 4, covering TypeScript asynchronous code, PostgreSQL, queries, stored routines and transactions.

Group members

Aske

Wanesa

Jeffrey

Nicolai


## B1 vs. B3 — TypeScript or Database Procedures?

Both implementations enrol a student in a course and update their total credits, but the difference is where the logic is executed.

**B1 keeps the business logic in TypeScript**, making it easier to understand, test, and maintain alongside the rest of the application. However, it requires multiple database queries and careful transaction management to ensure that both changes succeed or fail together.

**B3 performs the operation inside PostgreSQL** using a stored procedure. This reduces the number of round trips between the application and database and keeps the operation together, but it also makes the implementation more dependent on PostgreSQL and requires maintaining business logic inside the database.

For a system we had to maintain, we would generally prefer the TypeScript approach, as the course recommends, while using database transactions and constraints to maintain consistency. The cost of this choice is additional communication with the database and responsibility for coordinating the operations correctly.