#include "FibonacciFunction.hpp"

#include "../../widgets/generic/FunctionEntryRow.hpp"

#include <QVBoxLayout>

FibonacciFunction::FibonacciFunction(QWidget* parent)
    : FunctionWidget(parent)
{
    m_row = new FunctionEntryRow(tr("Fibonacci:"), /*index=*/0,
                                 FunctionReturnType::functionReturnFloat,
                                 /*rmVisible=*/false, /*insVisible=*/false,
                                 this);
    auto* layout = new QVBoxLayout(this);
    layout->addWidget(m_row);

    connect(m_row, &FunctionEntryRow::textChanged,
            this, [this]() { emit xmlChanged(); });
}

QList<FunctionReturnType> FibonacciFunction::supportedReturnTypes() const {
    return {
        FunctionReturnType::functionReturnInt,
        FunctionReturnType::functionReturnFloat,
        FunctionReturnType::functionReturnMakeListFun,
    };
}

QString FibonacciFunction::buildXMLString() const {
    return QStringLiteral("<Fun><Name>Fibonacci</Name><Entry>")
         + m_row->getText()
         + QStringLiteral("</Entry></Fun>");
}

void FibonacciFunction::populateFromXML(QXmlStreamReader& reader) {
    m_row->setText(nextChildInner(reader));
}

void FibonacciFunction::reset() {
    m_row->setText(QString());
}
