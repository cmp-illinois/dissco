#include "InverseFunction.hpp"

#include "../../widgets/generic/FunctionEntryRow.hpp"

#include <QVBoxLayout>

InverseFunction::InverseFunction(QWidget* parent)
    : FunctionWidget(parent)
{
    m_row = new FunctionEntryRow(tr("Number To Inverse:"), /*index=*/0,
                                 FunctionReturnType::functionReturnFloat,
                                 /*rmVisible=*/false, /*insVisible=*/false,
                                 this);
    auto* layout = new QVBoxLayout(this);
    layout->addWidget(m_row);

    connect(m_row, &FunctionEntryRow::textChanged,
            this, [this]() { emit xmlChanged(); });
}

QList<FunctionReturnType> InverseFunction::supportedReturnTypes() const {
    return {
        FunctionReturnType::functionReturnInt,
        FunctionReturnType::functionReturnFloat,
        FunctionReturnType::functionReturnMakeListFun,
    };
}

QString InverseFunction::buildXMLString() const {
    return QStringLiteral("<Fun><Name>Inverse</Name><Entry>")
         + m_row->getText()
         + QStringLiteral("</Entry></Fun>");
}

void InverseFunction::populateFromXML(QXmlStreamReader& reader) {
    m_row->setText(nextChildInner(reader));
}

void InverseFunction::reset() {
    m_row->setText(QString());
}
