table 50200 "Shopify Audit Snapshot"
{
    Caption = 'Shopify Audit Snapshot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(10; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }

        field(20; "Created By"; Text[100])
        {
            Caption = 'Created By';
            DataClassification = SystemMetadata;
        }

        field(30; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            DataClassification = SystemMetadata;
        }

        field(40; "Mapped Products"; Integer)
        {
            Caption = 'Mapped Products';
            DataClassification = SystemMetadata;
        }

        field(50; "Imported Orders"; Integer)
        {
            Caption = 'Imported Orders';
            DataClassification = SystemMetadata;
        }

        field(60; "Pending Buffers"; Integer)
        {
            Caption = 'Pending Buffers';
            DataClassification = SystemMetadata;
        }

        field(70; "Successful Buffers"; Integer)
        {
            Caption = 'Successful Buffers';
            DataClassification = SystemMetadata;
        }

        field(80; "Skipped Buffers"; Integer)
        {
            Caption = 'Skipped Buffers';
            DataClassification = SystemMetadata;
        }

        field(90; "Error Buffers"; Integer)
        {
            Caption = 'Error Buffers';
            DataClassification = SystemMetadata;
        }

        field(100; "Retry Attempts"; Integer)
        {
            Caption = 'Retry Attempts';
            DataClassification = SystemMetadata;
        }

        field(110; "Successful Log Entries"; Integer)
        {
            Caption = 'Successful Log Entries';
            DataClassification = SystemMetadata;
        }

        field(120; "Error Log Entries"; Integer)
        {
            Caption = 'Error Log Entries';
            DataClassification = SystemMetadata;
        }

        field(130; "BC Shopify Sales Orders"; Integer)
        {
            Caption = 'BC Shopify Sales Orders';
            DataClassification = SystemMetadata;
        }

        field(140; "Tagged Orders"; Integer)
        {
            Caption = 'Tagged Orders';
            DataClassification = SystemMetadata;
        }

        field(150; "Tag Errors"; Integer)
        {
            Caption = 'Tag Errors';
            DataClassification = SystemMetadata;
        }

        field(160; "Auto Import Orders"; Boolean)
        {
            Caption = 'Auto Import Orders';
            DataClassification = SystemMetadata;
        }

        field(170; "Auto Sync Inventory"; Boolean)
        {
            Caption = 'Auto Sync Inventory';
            DataClassification = SystemMetadata;
        }

        field(180; "Import Orders From"; DateTime)
        {
            Caption = 'Import Orders From';
            DataClassification = SystemMetadata;
        }

        field(190; "Job Queue Status"; Text[50])
        {
            Caption = 'Job Queue Status';
            DataClassification = SystemMetadata;
        }

        field(200; "Validation Passed"; Boolean)
        {
            Caption = 'Validation Passed';
            DataClassification = SystemMetadata;
        }

        field(210; "Validation Result"; Text[2048])
        {
            Caption = 'Validation Result';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(CreatedAt; "Created At")
        {
        }
    }
}