#include "LNFunction.hpp"

#include "../../widgets/generic/FunctionEntryRow.hpp"

#include <QVBoxLayout>

LNFunction::LNFunction(QWidget* parent)
    : FunctionWidget(parent)
{
    m_row = new FunctionEntryRow(tr("LN:"), /*index=*/0,
                                 FunctionReturnType::functionReturnFloat,
                                 /*rmVisible=*/false, /*insVisible=*/false,
                                 this);
    auto* layout = new QVBoxLayout(this);
    layout->addWidget(m_row);

    connect(m_row, &FunctionEntryRow::textChanged,
            this, [this]() { emit xmlChanged(); });
}

QList<FunctionReturnType> LNFunction::supportedReturnTypes() const {
    return {
        FunctionReturnType::functionReturnFloat,
        FunctionReturnType::functionReturnMakeListFun,
    };
}

QString LNFunction::buildXMLString() const {
    return QStringLiteral("<Fun><Name>LN</Name><Entry>")
         + m_row->getText()
         + QStringLiteral("</Entry></Fun>");
}

void LNFunction::populateFromXML(QXmlStreamReader& reader) {
    m_row->setText(nextChildInner(reader));
}

void LNFunction::reset() {
    m_row->setText(QString());
}
