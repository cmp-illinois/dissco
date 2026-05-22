#ifndef INVERSEFUNCTION_HPP
#define INVERSEFUNCTION_HPP

#include "FunctionWidget.hpp"

class FunctionEntryRow;

/** Inverse. Serializes as <Fun><Name>Inverse</Name><Entry>X</Entry></Fun>. */
class InverseFunction : public FunctionWidget {
    Q_OBJECT

public:
    explicit InverseFunction(QWidget* parent = nullptr);

    CMODFunction id() const override { return CMODFunction::functionInverse; }
    QString xmlName() const override { return QStringLiteral("Inverse"); }
    QString displayName() const override { return QStringLiteral("Inverse"); }
    QList<FunctionReturnType> supportedReturnTypes() const override;

    QString buildXMLString() const override;
    void populateFromXML(QXmlStreamReader& reader) override;
    void reset() override;

private:
    FunctionEntryRow* m_row;
};

#endif // INVERSEFUNCTION_HPP
