# Shared Notes

## Functional Requirements
1. Note
2. A Note is a editable document shared with all "family" members. Once created, anyone can "edit" the note.
3. Show Notes option in Tiles, clicking on which opens list of notes

## API Documentation
1. POST /notes

Creates a new note.
Payload -
```
{
  "Title":
  "Body":
  "Metadata":
}
```

## Data design
Table Name -> Notes

Schema ->
| Field           | Type                    |
| --------------- | ----------------------- |
| NoteId          | UUID                    |
| GroupCode       | VARCHAR (ForeignKey)    |
| CreatedBy       | UUID (ForeignKey)       |
| CreatedAt       | TIMESTAMPZ              |
| Title           | VARCHAR                 |
| Body            | JSONB                   |
| Metadata        | JSONB                   |
| UpdatedBy       | UUID (ForeignKey)       |
| UpdatedAt       | TIMESTAMPZ              |
| Revision        | INTEGER (Default 1)     |
