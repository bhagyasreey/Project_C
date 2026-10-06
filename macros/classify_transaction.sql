{% macro classify_transaction(transaction_type_column) %}

    {# Classify a transaction as an inflow, outflow, or other activity. #}

    case
        when upper(trim({{ transaction_type_column }})) in (
            'DEPOSIT',
            'CREDIT',
            'CASH_DEPOSIT',
            'TRANSFER_IN',
            'INTEREST_CREDIT',
            'REFUND'
        )
            then 'INFLOW'

        when upper(trim({{ transaction_type_column }})) in (
            'WITHDRAWAL',
            'ATM_WITHDRAWAL',
            'DEBIT',
            'TRANSFER_OUT',
            'PURCHASE',
            'PAYMENT',
            'FEE',
            'CHARGE'
        )
            then 'OUTFLOW'

        else 'OTHER'
    end

{% endmacro %}