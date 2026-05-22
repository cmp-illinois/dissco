#include "RandomFunction.hpp"

#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>

namespace {
    // Build a "label / line-edit / Insert Function" row. The button is
    // wired to fire `onInsertClicked()` so the caller can emit the nested
    // function request with the right target callback.
    QHBoxLayout* makeRow(QWidget* parent,
                         const QString& labelText,
                         QLineEdit*& edit,
                         QPushButton*& button) {
        auto* row = new QHBoxLayout;
        row->addWidget(new QLabel(labelText, parent));
        edit = new QLineEdit(parent);
        row->addWidget(edit);
        button = new QPushButton(QObject::tr("Insert Function"), parent);
        row->addWidget(button);
        return row;
    }
}

RandomFunction::RandomFunction(QWidget* parent)
    : FunctionWidget(parent)
{
    auto* layout = new QVBoxLayout(this);

    QPushButton* lowButton = nullptr;
    QPushButton* highButton = nullptr;
    layout->addLayout(makeRow(this, tr("Lower Bound:"), m_lowEdit, lowButton));
    layout->addLayout(makeRow(this, tr("Upper Bound:"), m_highEdit, highButton));

    // Legacy behavior seeded these fields with 0 / 1 on every combo-box
    // selection; this is more like a sensible initial default.
    m_lowEdit->setText(QStringLiteral("0"));
    m_highEdit->setText(QStringLiteral("1"));

    connect(m_lowEdit, &QLineEdit::textChanged, this, &FunctionWidget::xmlChanged);
    connect(m_highEdit, &QLineEdit::textChanged, this, &FunctionWidget::xmlChanged);

    auto requestNested = [this](QLineEdit* target) {
        emit nestedFunctionRequested(
            FunctionReturnType::functionReturnFloat,
            [target](const QString& result) {
                if (!result.isEmpty()) target->setText(result);
            });
    };
    connect(lowButton, &QPushButton::clicked, this, [this, requestNested]() {
        requestNested(m_lowEdit);
    });
    connect(highButton, &QPushButton::clicked, this, [this, requestNested]() {
        requestNested(m_highEdit);
    });
}

QList<FunctionReturnType> RandomFunction::supportedReturnTypes() const {
    return {
        FunctionReturnType::functionReturnFloat,
        FunctionReturnType::functionReturnMakeListFun,
    };
}

QString RandomFunction::buildXMLString() const {
    return QStringLiteral("<Fun><Name>Random</Name><Low>")
         + m_lowEdit->text()
         + QStringLiteral("</Low><High>")
         + m_highEdit->text()
         + QStringLiteral("</High></Fun>");
}

void RandomFunction::populateFromXML(QXmlStreamReader& reader) {
    m_lowEdit->setText(nextChildInner(reader));
    m_highEdit->setText(nextChildInner(reader));
}

void RandomFunction::reset() {
    m_lowEdit->setText(QStringLiteral("0"));
    m_highEdit->setText(QStringLiteral("1"));
}
