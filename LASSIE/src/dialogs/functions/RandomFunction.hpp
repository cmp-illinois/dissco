#ifndef RANDOMFUNCTION_HPP
#define RANDOMFUNCTION_HPP

#include "FunctionWidget.hpp"

class FunctionEntryRow;

/** Uniform float random. Serializes as
 *  <Fun><Name>Random</Name><Low>X</Low><High>Y</High></Fun>. */
class RandomFunction : public FunctionWidget {
    Q_OBJECT

public:
    explicit RandomFunction(QWidget* parent = nullptr);

    CMODFunction id() const override { return CMODFunction::functionRandom; }
    QString xmlName() const override { return QStringLiteral("Random"); }
    QString displayName() const override { return QStringLiteral("Random"); }
    QList<FunctionReturnType> supportedReturnTypes() const override;

    QString buildXMLString() const override;
    void populateFromXML(QXmlStreamReader& reader) override;
    void reset() override;

private:
    FunctionEntryRow* m_lowRow;
    FunctionEntryRow* m_highRow;
};

#endif // RANDOMFUNCTION_HPP
