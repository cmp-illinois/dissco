#include "RandomFunction.hpp"

#include "../../widgets/generic/FunctionEntryRow.hpp"

#include <QVBoxLayout>

RandomFunction::RandomFunction(QWidget* parent)
    : FunctionWidget(parent)
{
    m_lowRow  = new FunctionEntryRow(tr("Lower Bound:"), /*index=*/0,
                                     FunctionReturnType::functionReturnFloat,
                                     /*rmVisible=*/false, /*insVisible=*/false,
                                     this);
    m_highRow = new FunctionEntryRow(tr("Upper Bound:"), /*index=*/1,
                                     FunctionReturnType::functionReturnFloat,
                                     /*rmVisible=*/false, /*insVisible=*/false,
                                     this);

    auto* layout = new QVBoxLayout(this);
    layout->addWidget(m_lowRow);
    layout->addWidget(m_highRow);

    // Legacy seeded these on every combo-box selection; this is more like
    // a sensible initial default.
    m_lowRow->setText(QStringLiteral("0"));
    m_highRow->setText(QStringLiteral("1"));

    auto forward = [this]() { emit xmlChanged(); };
    connect(m_lowRow,  &FunctionEntryRow::textChanged, this, forward);
    connect(m_highRow, &FunctionEntryRow::textChanged, this, forward);
}

QList<FunctionReturnType> RandomFunction::supportedReturnTypes() const {
    return {
        FunctionReturnType::functionReturnFloat,
        FunctionReturnType::functionReturnMakeListFun,
    };
}

QString RandomFunction::buildXMLString() const {
    return QStringLiteral("<Fun><Name>Random</Name><Low>")
         + m_lowRow->getText()
         + QStringLiteral("</Low><High>")
         + m_highRow->getText()
         + QStringLiteral("</High></Fun>");
}

void RandomFunction::populateFromXML(QXmlStreamReader& reader) {
    m_lowRow->setText(nextChildInner(reader));
    m_highRow->setText(nextChildInner(reader));
}

void RandomFunction::reset() {
    m_lowRow->setText(QStringLiteral("0"));
    m_highRow->setText(QStringLiteral("1"));
}
