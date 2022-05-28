package db

import (
	"context"
	"database/sql"
	"fmt"
)

// Store provide all functions to execute db queries and transactions
type Store struct {
	*Queries
	db *sql.DB
}

func NewStore(db *sql.DB) *Store {
	return &Store{
		Queries: New(db),
		db:      db,
	}
}

// execTx executes a function within a database transaction
func (store *Store) execTx(ctx context.Context, fn func(*Queries) error) error {
	tx, err := store.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	q := New(tx)
	err = fn(q)
	if err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
		}
		return err
	}

	return tx.Commit()
}

type TransferTxParams struct {
	FromAccountID int64 `json:"from_account_id"`
	ToAccountID   int64 `json:"to_account_id"`
	Amount        int64 `json:"amount"`
}

type TransferTXResult struct {
	Transfer    Transfer `json:"transfer"`
	FromAccount Account  `json:"from_account"`
	ToAccount   Account  `json:"to_account"`
	FromEntry   Entry    `json:"from_entry"`
	ToEntry     Entry    `json:"to_entry"`
}

// TransferTx performs a monery transfer from one account to the other.
// It creates a transfer record, add account entries, and update account's balance within a singe database transaction
func (store *Store) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTXResult, error) {
	var result TransferTXResult

	err := store.execTx(ctx, func(q *Queries) error {
		var err error
		result.Transfer, err = q.CreateTransferWithReturn(ctx, CreateTransferParams{
			FromAccountID: arg.FromAccountID,
			ToAccountID:   arg.ToAccountID,
			Amount:        arg.Amount,
		})
		if err != nil {
			return err
		}

		result.FromEntry, err = q.CreateEntryWithReturn(ctx, CreateEntryParams{
			AccountID: arg.FromAccountID,
			Amount:    -arg.Amount,
		})
		if err != nil {
			return err
		}

		result.ToEntry, err = q.CreateEntryWithReturn(ctx, CreateEntryParams{
			AccountID: arg.ToAccountID,
			Amount:    arg.Amount,
		})
		if err != nil {
			return err
		}

		// TODO: update accounts' balance

		return nil
	})

	return result, err
}

func (q *Queries) CreateTransferWithReturn(ctx context.Context, arg CreateTransferParams) (Transfer, error) {
	var transfer Transfer
	sqlResult, err := q.CreateTransfer(ctx, arg)
	if err != nil {
		return transfer, err
	}

	id, err := sqlResult.LastInsertId()
	if err != nil {
		return transfer, err
	}

	transfer.ID = id
	transfer.FromAccountID = arg.FromAccountID
	transfer.ToAccountID = arg.ToAccountID
	transfer.Amount = arg.Amount

	return transfer, nil
}

func (q *Queries) CreateEntryWithReturn(ctx context.Context, arg CreateEntryParams) (Entry, error) {
	var entry Entry
	sqlResult, err := q.CreateEntry(ctx, arg)
	if err != nil {
		return entry, err
	}

	id, err := sqlResult.LastInsertId()
	if err != nil {
		return entry, err
	}

	entry.ID = id
	entry.AccountID = arg.AccountID
	entry.Amount = arg.Amount

	return entry, nil
}
